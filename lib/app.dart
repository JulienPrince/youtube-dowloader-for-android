import 'package:flutter/material.dart';
import 'data/download_repository.dart';
import 'settings/settings_controller.dart';
import 'theme/app_theme.dart';
import 'ui/splash_screen.dart';
import 'ui/webview_screen.dart';
import 'ui/onboarding_screen.dart';

class App extends StatelessWidget {
  final DownloadRepository repo;
  final SettingsController settings;
  final bool onboarded;
  const App({
    super.key,
    required this.repo,
    required this.settings,
    required this.onboarded,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Tubebox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(settings.accent),
        darkTheme: AppTheme.dark(settings.accent),
        themeMode: settings.themeMode,
        home: SplashScreen(
          next: onboarded
              ? WebViewScreen(repo: repo, settings: settings)
              : OnboardingScreen(repo: repo, settings: settings),
        ),
      ),
    );
  }
}
