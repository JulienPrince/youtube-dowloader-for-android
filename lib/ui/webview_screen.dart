import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../extractor/video_extractor.dart';
import '../extractor/youtube_explode_extractor.dart';
import '../services/download_service.dart';
import '../data/download_repository.dart';
import '../settings/settings_service.dart';
import '../settings/settings_controller.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import '../models/download_format.dart';
import '../models/download_task.dart';
import '../theme/app_theme.dart';
import '../utils/url_utils.dart';
import 'widgets/format_sheet.dart';
import 'widgets/playlist_choice_dialog.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

class WebViewScreen extends StatefulWidget {
  final DownloadRepository repo;
  final SettingsController settings;
  const WebViewScreen({super.key, required this.repo, required this.settings});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  String _currentUrl = 'https://m.youtube.com';
  final _settings = SettingsService();
  late final _extractor = YoutubeExplodeExtractor();
  late final _downloader = DownloadService(widget.repo, _extractor);

  bool _busy = false; // analyse en cours (extraction + métadonnées)

  bool get _onVideo => UrlUtils.videoId(_currentUrl) != null;

  Future<void> _onDownloadPressed() async {
    if (_busy) return;
    final url = _currentUrl;
    setState(() => _busy = true);

    // Phase analyse (réseau) : extraction + métadonnées playlist.
    final VideoInfo info;
    PlaylistMeta? meta;
    try {
      info = await _extractor.extractVideo(url);
    } catch (e) {
      debugPrint('[Tubebox] extractVideo failed for "$url": $e');
      if (mounted) setState(() => _busy = false);
      _toast('Impossible de lire cette vidéo');
      return;
    }
    // Vraie playlist (PL…) énumérable seulement. Les Mix/Radio (RD…) ne le sont
    // pas -> on ignore et on télécharge la vidéo seule.
    final isMix = UrlUtils.isMix(url);
    if (UrlUtils.isPlaylist(url) && !isMix) {
      try {
        meta = await _extractor.playlistMeta(url);
      } catch (e) {
        debugPrint('[Tubebox] playlistMeta failed for "$url": $e');
        meta = null;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (isMix) {
      _toast('Mix/Radio YouTube : seule cette vidéo sera téléchargée');
    }

    // Phase interactive : choix uniquement si la playlist est réellement énumérée.
    bool wholePlaylist = false;
    if (meta != null && meta.count > 0) {
      final choice = await showPlaylistChoiceDialog(context,
          playlistTitle: meta.title, count: meta.count, videoTitle: info.title);
      if (choice == null) return;
      wholePlaylist = choice == PlaylistChoice.all;
    }

    // Filtre qualité vidéo max (les options audio sont conservées).
    final options = _capVideo(info.options, await _settings.maxVideoHeight());

    // Format par défaut : si défini (MP4/MP3), on saute le bottom sheet.
    final forced =
        _settings.defaultDownloadFormat(await _settings.defaultFormat());
    final StreamOption opt;
    if (forced != null) {
      final match = options.where((o) => o.format == forced);
      if (match.isEmpty) {
        _toast('Format ${forced == DownloadFormat.mp3 ? "MP3" : "MP4"} indisponible');
        return;
      }
      opt = match.first;
    } else {
      final lastLabel = await _settings.lastFormatLabel();
      if (!mounted) return;
      final picked = await showFormatSheet(context, options, lastLabel);
      if (picked == null) return;
      opt = picked;
      await _settings.setLastFormatLabel(opt.label);
    }

    _toast('Téléchargement lancé…');

    await FlutterForegroundTask.startService(
      notificationTitle: 'Téléchargement en cours',
      notificationText: 'Tubebox',
    );
    try {
      if (wholePlaylist) {
        final (ok, total) =
            await _downloader.downloadPlaylist(_extractor.extractPlaylist(url), opt.format);
        _toast('$ok/$total téléchargés');
      } else {
        final success = await _downloader.downloadOne(info, opt);
        _toast(success ? 'Terminé : ${info.title}' : 'Échec du téléchargement');
      }
    } finally {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _retry(DownloadTask task) async {
    try {
      final info = await _extractor
          .extractVideo('https://www.youtube.com/watch?v=${task.id}');
      final opt = info.options.firstWhere((o) => o.format == task.format,
          orElse: () => info.options.first);
      await _downloader.downloadOne(info, opt);
    } catch (e) {
      debugPrint('[Tubebox] retry failed: $e');
      _toast('Échec de la reprise');
    }
  }

  List<StreamOption> _capVideo(List<StreamOption> opts, int maxH) {
    if (maxH <= 0) return opts;
    int h(StreamOption o) {
      final m = RegExp(r'(\d+)p').firstMatch(o.label);
      return m != null ? int.parse(m.group(1)!) : 0;
    }
    final audio = opts.where((o) => o.format != DownloadFormat.mp4).toList();
    final videos = opts.where((o) => o.format == DownloadFormat.mp4).toList();
    final kept = videos.where((o) => h(o) <= maxH).toList();
    if (kept.isEmpty && videos.isNotEmpty) {
      videos.sort((a, b) => h(a).compareTo(h(b)));
      kept.add(videos.first);
    }
    return [...kept, ...audio];
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tubebox', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_done_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DownloadsScreen(repo: widget.repo, onRetry: _retry))),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SettingsScreen(settings: widget.settings))),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
        onUpdateVisitedHistory: (controller, url, _) {
          if (url != null) setState(() => _currentUrl = url.toString());
        },
      ),
      floatingActionButton: _onVideo
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _onDownloadPressed,
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_busy ? 'Analyse…' : 'Télécharger',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _extractor.dispose();
    super.dispose();
  }
}
