// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:nightride/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/splash_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await NotificationService.init();
    await NotificationService.requestPermission();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('dark_mode') ?? true;
  final savedAccent = prefs.getInt('accent_index') ?? 0;

  runApp(ProviderScope(
    overrides: [
      homeDarkToggleProvider.overrideWith((ref) => savedDark),
      accentColorIndexProvider.overrideWith((ref) => savedAccent),
    ],
    child: const MyApp(),
  ));
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

    // Persist preference changes
    ref.listen(homeDarkToggleProvider, (_, next) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool('dark_mode', next));
    });
    ref.listen(accentColorIndexProvider, (_, next) {
      SharedPreferences.getInstance()
          .then((p) => p.setInt('accent_index', next));
    });

    // Prevent ScreenUtil .w from over-inflating on foldables/tablets.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final physW = view.physicalSize.width / view.devicePixelRatio;
    final suDesignWidth = physW > 600
        ? physW.clamp(600.0, 720.0)
        : physW.clamp(390.0, 480.0);

    return GlassMorphismThemeProvider(
      child: ScreenUtilInit(
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
    ));
  }
}
