// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ✅ IMPORTANT: Mapbox package exports its own `Size` class.
// Hide it so Flutter's `Size` (dart:ui) is used by ScreenUtilInit.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/auth/sign_up_page.dart';
import 'package:nightride/pages/forgotPw/create_new_password_page.dart';
import 'package:nightride/pages/forgotPw/forgot_pw_OTP.dart';
import 'package:nightride/pages/home_page.dart';
import 'package:nightride/pages/map_page.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/pages/splash_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load(fileName: '.env');
  final String token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  if (token.isNotEmpty) {
    MapboxOptions.setAccessToken(token);
  }

  runApp(const ProviderScope(child: MyApp()));
}

Locale _toLocale(HomeLanguage lang) {
  switch (lang) {
    case HomeLanguage.de: return const Locale('de');
    case HomeLanguage.fr: return const Locale('fr');
    case HomeLanguage.es: return const Locale('es');
    case HomeLanguage.it: return const Locale('it');
    case HomeLanguage.nl: return const Locale('nl');
    case HomeLanguage.sv: return const Locale('sv');
    case HomeLanguage.pt: return const Locale('pt');
    case HomeLanguage.ja: return const Locale('ja');
    case HomeLanguage.ar: return const Locale('ar');
    case HomeLanguage.ko: return const Locale('ko');
    case HomeLanguage.zh: return const Locale('zh');
    case HomeLanguage.en: return const Locale('en');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = ref.watch(homeDarkToggleProvider);
    final HomeLanguage lang = ref.watch(homeLanguageProvider);
    final Color accent = kAccentColors[ref.watch(accentColorIndexProvider)];

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return MaterialApp(
          title: 'NightLife',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light.copyWith(
            colorScheme: AppTheme.light.colorScheme.copyWith(primary: accent, secondary: accent),
          ),
          darkTheme: AppTheme.dark.copyWith(
            colorScheme: AppTheme.dark.colorScheme.copyWith(primary: accent, secondary: accent),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          locale: _toLocale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
