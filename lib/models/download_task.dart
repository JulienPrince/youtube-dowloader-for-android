import 'download_format.dart';

enum DownloadStatus { queued, downloading, converting, done, failed }

class DownloadTask {
  final String id;
  final String title;
  final DownloadFormat format;
  final DownloadStatus status;
  final String? localPath;
  final double progress;
  final String? error;
  final DateTime createdAt;

  const DownloadTask({
    required this.id,
    required this.title,
    required this.format,
    required this.status,
    required this.localPath,
    required this.progress,
    required this.error,
    required this.createdAt,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    String? localPath,
    double? progress,
    String? error,
  }) =>
      DownloadTask(
        id: id,
        title: title,
        format: format,
        status: status ?? this.status,
        localPath: localPath ?? this.localPath,
        progress: progress ?? this.progress,
        error: error ?? this.error,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'format': format.name,
        'status': status.name,
        'localPath': localPath,
        'progress': progress,
        'error': error,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory DownloadTask.fromMap(Map<String, Object?> m) => DownloadTask(
        id: m['id'] as String,
        title: m['title'] as String,
        format: DownloadFormat.values.byName(m['format'] as String),
        status: DownloadStatus.values.byName(m['status'] as String),
        localPath: m['localPath'] as String?,
        progress: (m['progress'] as num).toDouble(),
        error: m['error'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      );
}
