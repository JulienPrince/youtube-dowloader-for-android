import 'download_format.dart';

class StreamOption {
  final DownloadFormat format;
  final String label;        // ex "720p", "Audio 128kbps"
  final String url;          // url du flux (expirable)
  final String container;    // mp4, m4a, webm
  final int? bitrate;
  final int? sizeBytes;      // taille connue du flux (pour la progression)

  // Référence opaque au flux natif de l'extracteur (ex. StreamInfo de
  // youtube_explode). Sert à télécharger via le client de l'extracteur, qui
  // évite le throttling de googlevideo (un GET HTTP générique est bridé).
  final Object? source;

  const StreamOption({
    required this.format,
    required this.label,
    required this.url,
    required this.container,
    this.bitrate,
    this.sizeBytes,
    this.source,
  });
}
