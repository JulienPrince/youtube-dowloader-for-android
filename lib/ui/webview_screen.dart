import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../extractor/video_extractor.dart';
import '../extractor/youtube_explode_extractor.dart';
import '../services/download_service.dart';
import '../data/download_repository.dart';
import '../settings/settings_service.dart';
import '../models/video_info.dart';
import '../theme/app_theme.dart';
import '../utils/url_utils.dart';
import 'widgets/format_sheet.dart';
import 'widgets/playlist_choice_dialog.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

class WebViewScreen extends StatefulWidget {
  final DownloadRepository repo;
  const WebViewScreen({super.key, required this.repo});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  String _currentUrl = 'https://m.youtube.com';
  final _settings = SettingsService();
  late final _extractor = YoutubeExplodeExtractor();
  late final _downloader = DownloadService(widget.repo);

  bool get _onVideo => UrlUtils.videoId(_currentUrl) != null;

  Future<void> _onDownloadPressed() async {
    final url = _currentUrl;

    VideoInfo info;
    try {
      info = await _extractor.extractVideo(url);
    } catch (_) {
      _toast('Impossible de lire cette vidéo');
      return;
    }

    bool wholePlaylist = false;
    if (UrlUtils.isPlaylist(url)) {
      PlaylistMeta meta;
      try {
        meta = await _extractor.playlistMeta(url);
      } catch (_) {
        meta = const PlaylistMeta('Playlist', 0);
      }
      if (!mounted) return;
      final choice = await showPlaylistChoiceDialog(context,
          playlistTitle: meta.title, count: meta.count, videoTitle: info.title);
      if (choice == null) return;
      wholePlaylist = choice == PlaylistChoice.all;
    }

    final lastLabel = await _settings.lastFormatLabel();
    if (!mounted) return;
    final opt = await showFormatSheet(context, info.options, lastLabel);
    if (opt == null) return;
    await _settings.setLastFormatLabel(opt.label);

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
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DownloadsScreen(repo: widget.repo))),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
              onPressed: _onDownloadPressed,
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.download),
              label: const Text('Télécharger', style: TextStyle(fontWeight: FontWeight.w600)),
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
