import 'package:flutter/material.dart';
import 'data/download_repository.dart';
import 'settings/settings_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = DownloadRepository();
  await repo.open();
  final settings = SettingsService();
  final themeMode = await settings.themeMode();
  final accent = await settings.accent();
  final onboarded = await settings.onboarded();
  runApp(App(repo: repo, themeMode: themeMode, accent: accent, onboarded: onboarded));
}
