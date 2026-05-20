import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'data/download_repository.dart';
import 'settings/settings_service.dart';
import 'settings/settings_controller.dart';
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
  await repo.failStale(); // vide les téléchargements zombies d'un process tué
  final service = SettingsService();
  final settings = await SettingsController.load(service);
  final onboarded = await service.onboarded();
  runApp(App(repo: repo, settings: settings, onboarded: onboarded));
}
