import 'package:flutter/material.dart';
import 'data/download_repository.dart';
import 'theme/app_theme.dart';
import 'ui/webview_screen.dart';
import 'ui/onboarding_screen.dart';

class App extends StatelessWidget {
  final DownloadRepository repo;
  final ThemeMode themeMode;
  final Color accent;
  final bool onboarded;
  const App({
    super.key,
    required this.repo,
    required this.themeMode,
    required this.accent,
    required this.onboarded,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tubebox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: themeMode,
      home: onboarded ? WebViewScreen(repo: repo) : OnboardingScreen(repo: repo),
    );
  }
}
