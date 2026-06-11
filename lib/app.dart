import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/home_shell.dart';

class ExpensioApp extends ConsumerStatefulWidget {
  const ExpensioApp({super.key});

  @override
  ConsumerState<ExpensioApp> createState() => _ExpensioAppState();
}

class _ExpensioAppState extends ConsumerState<ExpensioApp> {
  @override
  void initState() {
    super.initState();
    _syncSplashAndMonet();
  }

  Future<void> _syncSplashAndMonet() async {
    // Wait for the same native calls DynamicColorBuilder uses internally
    // to sync our timing with the Monet color loading
    try {
      await DynamicColorPlugin.getCorePalette();
      await DynamicColorPlugin.getAccentColor();
    } catch (_) {}

    // When colors are ready, DynamicColorBuilder will rebuild
    // Wait two frames to ensure Flutter has fully applied the new Monet theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final useDynamic = ref.watch(dynamicColorProvider);
    final onboardingDone = ref.watch(onboardingCompleteProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Expensio',
          debugShowCheckedModeBanner: false,
          themeMode: _resolveThemeMode(themeMode),
          theme: ExpensioTheme.lightTheme(useDynamic ? lightDynamic : null),
          darkTheme: ExpensioTheme.darkTheme(
            useDynamic ? darkDynamic : null,
            themeMode == 'night',
          ),
          home: onboardingDone ? const HomeShell() : const OnboardingScreen(),
        );
      },
    );
  }

  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'night':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
