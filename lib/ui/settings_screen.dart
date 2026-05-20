import 'package:flutter/material.dart';
import '../settings/settings_service.dart';
import '../settings/settings_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController settings;
  const SettingsScreen({super.key, required this.settings});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();

  DefaultFormat _defFormat = DefaultFormat.ask;
  int _audioKbps = 320;
  int _maxVideo = 1080;
  String _musicDir = 'Tubebox';
  String _videoDir = 'Tubebox';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await _service.defaultFormat();
    final a = await _service.audioKbps();
    final v = await _service.maxVideoHeight();
    final md = await _service.musicDir();
    final vd = await _service.videoDir();
    if (!mounted) return;
    setState(() {
      _defFormat = f;
      _audioKbps = a;
      _maxVideo = v;
      _musicDir = (md == null || md.isEmpty) ? 'Tubebox' : md;
      _videoDir = (vd == null || vd.isEmpty) ? 'Tubebox' : vd;
    });
  }

  String get _defFormatLabel => switch (_defFormat) {
        DefaultFormat.ask => 'Demander à chaque fois',
        DefaultFormat.mp4 => 'MP4 (vidéo)',
        DefaultFormat.mp3 => 'MP3 (audio)',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(children: [
        _section(c, "Moteur d'extraction"),
        _engineCard(c, 'youtube_explode_dart', 'Pur Dart. Rapide, léger. Par défaut.', 'v1', active: true),
        _engineCard(c, 'yt-dlp (bridge natif)', 'Plus robuste, plus lourd. Bientôt.', 'Bientôt', active: false, disabled: true),

        _section(c, 'Apparence'),
        _row(c, 'Thème', child: _themeSelector(c)),
        _row(c, "Couleur d'accent", child: _accentSwatches(c)),

        _section(c, 'Par défaut'),
        _tapRow(c, 'Format par défaut', _defFormatLabel, _pickFormat),
        _tapRow(c, 'Qualité audio (MP3)', '$_audioKbps kbps', _pickAudio),
        _tapRow(c, 'Qualité vidéo max', _maxVideo <= 0 ? 'Meilleure' : '${_maxVideo}p', _pickVideo),

        _section(c, 'Stockage'),
        _tapRow(c, 'Dossier musique', 'Music/$_musicDir', () => _editFolder(true),
            icon: Icons.folder_outlined),
        _tapRow(c, 'Dossier vidéos', 'Movies/$_videoDir', () => _editFolder(false),
            icon: Icons.folder_outlined),

        _section(c, 'À propos'),
        _tapRow(c, 'Version', '1.0.0', null),
        _tapRow(c, 'Build', '2026.05.20 · APK', null),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ---- pickers ----

  Future<void> _pickFormat() async {
    final v = await _choice<DefaultFormat>('Format par défaut', _defFormat, const [
      ('Demander à chaque fois', DefaultFormat.ask),
      ('MP4 (vidéo)', DefaultFormat.mp4),
      ('MP3 (audio)', DefaultFormat.mp3),
    ]);
    if (v != null) {
      await _service.setDefaultFormat(v);
      setState(() => _defFormat = v);
    }
  }

  Future<void> _pickAudio() async {
    final v = await _choice<int>('Qualité audio (MP3)', _audioKbps, const [
      ('320 kbps · Haute', 320),
      ('256 kbps', 256),
      ('192 kbps', 192),
      ('128 kbps · Léger', 128),
    ]);
    if (v != null) {
      await _service.setAudioKbps(v);
      setState(() => _audioKbps = v);
    }
  }

  Future<void> _pickVideo() async {
    final v = await _choice<int>('Qualité vidéo max', _maxVideo, const [
      ('Meilleure dispo', 0),
      ('1080p', 1080),
      ('720p', 720),
      ('360p', 360),
    ]);
    if (v != null) {
      await _service.setMaxVideoHeight(v);
      setState(() => _maxVideo = v);
    }
  }

  Future<void> _editFolder(bool music) async {
    final ctrl = TextEditingController(text: music ? _musicDir : _videoDir);
    final c = context.c;
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(music ? 'Dossier musique' : 'Dossier vidéos',
            style: TextStyle(color: c.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.text),
          decoration: InputDecoration(
            prefixText: music ? 'Music/' : 'Movies/',
            prefixStyle: TextStyle(color: c.muted),
            hintText: 'Tubebox',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.accent),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (v == null) return;
    final name = v.isEmpty ? 'Tubebox' : v;
    if (music) {
      await _service.setMusicDir(name);
      setState(() => _musicDir = name);
    } else {
      await _service.setVideoDir(name);
      setState(() => _videoDir = name);
    }
  }

  Future<T?> _choice<T>(String title, T current, List<(String, T)> options) {
    final c = context.c;
    return showDialog<T>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: c.surface,
        title: Text(title, style: TextStyle(color: c.text, fontSize: 17)),
        children: options.map((o) {
          final selected = o.$2 == current;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, o.$2),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20, color: selected ? c.accent : c.muted),
              const SizedBox(width: 12),
              Text(o.$1, style: TextStyle(color: c.text, fontSize: 15)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ---- widgets ----

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

  Widget _tapRow(TubeboxColors c, String title, String value, VoidCallback? onTap,
          {IconData? icon}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border, width: 0.5))),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, size: 18, color: c.muted), const SizedBox(width: 12)],
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: c.text))),
            Text(value, style: TextStyle(fontSize: 13, color: c.muted)),
            if (onTap != null) Icon(Icons.chevron_right, size: 16, color: c.faint),
          ]),
        ),
      );

  Widget _themeSelector(TubeboxColors c) => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
        ],
        selected: {widget.settings.themeMode},
        showSelectedIcon: false,
        onSelectionChanged: (s) => widget.settings.setThemeMode(s.first),
      );

  Widget _accentSwatches(TubeboxColors c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: kAccentOptions.map((color) {
          final on = color.toARGB32() == widget.settings.accent.toARGB32();
          return GestureDetector(
            onTap: () => widget.settings.setAccent(color),
            child: Container(
              width: 26, height: 26, margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: Border.all(color: on ? c.text : Colors.transparent, width: 2)),
            ),
          );
        }).toList(),
      );
}
