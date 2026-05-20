import 'package:flutter/material.dart';
import '../settings/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  ThemeMode _mode = ThemeMode.system;
  Color _accent = kAccentDefault;

  @override
  void initState() {
    super.initState();
    _settings.themeMode().then((m) => setState(() => _mode = m));
    _settings.accent().then((a) => setState(() => _accent = a));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg, surfaceTintColor: Colors.transparent, elevation: 0,
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(children: [
        _section(c, "Moteur d'extraction"),
        _engineCard(c, 'youtube_explode_dart', 'Pur Dart. Rapide, léger. Par défaut.', 'v1', active: true),
        _engineCard(c, 'yt-dlp (bridge natif)', 'Plus robuste, plus lourd. Bientôt.', 'Bientôt', active: false, disabled: true),
        _section(c, 'Apparence'),
        _row(c, 'Thème', child: _themeSelector()),
        _row(c, "Couleur d'accent", child: _accentSwatches(c)),
        _section(c, 'Par défaut'),
        _staticRow(c, 'Format par défaut', 'Demander à chaque fois'),
        _staticRow(c, 'Qualité audio', '320 kbps'),
        _staticRow(c, 'Qualité vidéo max', '1080p'),
        _section(c, 'Stockage'),
        _staticRow(c, 'Dossier musique', 'Music/Tubebox', icon: Icons.folder_outlined),
        _staticRow(c, 'Dossier vidéos', 'Movies/Tubebox', icon: Icons.folder_outlined),
        _section(c, 'À propos'),
        _staticRow(c, 'Version', '1.0.0'),
        _staticRow(c, 'Build', '2026.05.20 · APK'),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _section(TubeboxColors c, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: c.muted)),
      );

  Widget _engineCard(TubeboxColors c, String title, String sub, String tag,
      {required bool active, bool disabled = false}) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? c.accent.withValues(alpha: 0.07) : c.surface2,
          border: Border.all(color: active ? c.accent.withValues(alpha: 0.35) : c.border, width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20, height: 20, margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? c.accent : c.border2, width: active ? 5 : 1.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(title,
                    style: context.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.text))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: active ? c.accent : c.border, borderRadius: BorderRadius.circular(999)),
                  child: Text(tag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : c.muted)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 12, color: c.muted, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(TubeboxColors c, String title, {required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border, width: 0.5))),
        child: Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: c.text))),
          child,
        ]),
      );

  Widget _staticRow(TubeboxColors c, String title, String value, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border, width: 0.5))),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: c.muted), const SizedBox(width: 12)],
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: c.text))),
          Text(value, style: TextStyle(fontSize: 13, color: c.muted)),
          Icon(Icons.chevron_right, size: 16, color: c.faint),
        ]),
      );

  Widget _themeSelector() => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) {
          setState(() => _mode = s.first);
          _settings.setThemeMode(s.first);
        },
      );

  Widget _accentSwatches(TubeboxColors c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: kAccentOptions.map((color) {
          final on = color.toARGB32() == _accent.toARGB32();
          return GestureDetector(
            onTap: () {
              setState(() => _accent = color);
              _settings.setAccent(color);
            },
            child: Container(
              width: 24, height: 24, margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: Border.all(color: on ? c.text : Colors.transparent, width: 2)),
            ),
          );
        }).toList(),
      );
}
