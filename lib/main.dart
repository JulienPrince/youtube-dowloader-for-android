import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'data/download_repository.dart';
import 'settings/settings_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'downloads',
      channelName: 'Téléchargements',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
  final repo = DownloadRepository();
  await repo.open();
  final settings = SettingsService();
  final themeMode = await settings.themeMode();
  final accent = await settings.accent();
  final onboarded = await settings.onboarded();
  runApp(App(repo: repo, themeMode: themeMode, accent: accent, onboarded: onboarded));
}
