// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:nightride/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Mapbox exports its own `Size` class — hide it so Flutter's Size is used by ScreenUtilInit.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/splash_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await NotificationService.init();
    await NotificationService.requestPermission();
  } catch (_) {}

  if (!kIsWeb) {
    // Primary source: --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx at build time.
    // Fallback for local dev: .env file (NOT bundled in production builds).
    const String dartDefineToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    String token = dartDefineToken;
    try {
      await dotenv.load(fileName: '.env');
      token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? dartDefineToken;
    } catch (_) {
      // .env is not bundled in production — dart-define token is used.
    }
    if (token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
    }
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

    // Prevent ScreenUtil .w from over-inflating on foldables/tablets.
    // On phones (≤390 dp) the design size stays 390×844 — no change.
    // On wide devices (e.g. Honor Magic V3 unfolded ~719–821 dp) the design
    // width is capped at 480 dp so .w values grow at most ~23% instead of ~85%.
    // AppResponsive still receives the real screen width via MaterialApp's
    // own MediaQuery, so all adaptive layout helpers remain correct.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final physW = view.physicalSize.width / view.devicePixelRatio;
    final suDesignWidth = physW.clamp(390.0, 480.0);

    return ScreenUtilInit(
      designSize: Size(suDesignWidth, 844),
      minTextAdapt: true,
      splitScreenMode: true,
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
