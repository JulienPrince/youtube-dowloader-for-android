import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/download_repository.dart';
import '../settings/settings_service.dart';
import '../theme/app_theme.dart';
import 'webview_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final DownloadRepository repo;
  const OnboardingScreen({super.key, required this.repo});

  Future<void> _start(BuildContext context) async {
    await [
      Permission.storage, Permission.audio, Permission.videos, Permission.notification,
    ].request();
    await SettingsService().setOnboarded();
    if (!context.mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => WebViewScreen(repo: repo)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final perms = <(IconData, String, String)>[
      (Icons.folder_outlined, 'Stockage', 'Pour ranger les fichiers dans Musique / Vidéos.'),
      (Icons.notifications_outlined, 'Notifications', 'Pour vous prévenir quand un téléchargement est prêt.'),
      (Icons.bolt_outlined, "Tâche d'arrière-plan", 'Pour finir les téléchargements écran éteint.'),
    ];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tubebox', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
              Text('1 / 1', style: TextStyle(fontSize: 11, color: c.muted)),
            ]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.download, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 28),
                  Text('Téléchargez vos vidéos préférées.',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: c.text, height: 1.15)),
                  const SizedBox(height: 12),
                  Text("Naviguez sur YouTube comme d'habitude. Une fois sur une vidéo, touchez « Télécharger ».",
                      style: TextStyle(fontSize: 14, color: c.muted, height: 1.45)),
                  const SizedBox(height: 28),
                  ...perms.map((p) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border, width: 0.5))),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36, alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
                            child: Icon(p.$1, size: 18, color: c.text2),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                              const SizedBox(height: 1),
                              Text(p.$3, style: TextStyle(fontSize: 12, color: c.muted)),
                            ]),
                          ),
                        ]),
                      )),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                onPressed: () => _start(context),
                child: const Text('Commencer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
