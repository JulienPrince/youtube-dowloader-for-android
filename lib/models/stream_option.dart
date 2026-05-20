import 'download_format.dart';

class StreamOption {
  final DownloadFormat format;
  final String label;        // ex "720p", "Audio 128kbps"
  final String url;          // url du flux (expirable)
  final String container;    // mp4, m4a, webm
  final int? bitrate;

  const StreamOption({
    required this.format,
    required this.label,
    required this.url,
    required this.container,
    this.bitrate,
  });
}
