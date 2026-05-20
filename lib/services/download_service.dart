import 'package:dio/dio.dart';
import '../data/download_repository.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import 'storage_service.dart';
import 'conversion_service.dart';

class DownloadService {
  final Dio _dio;
  final DownloadRepository _repo;
  final ConversionService _conversion;

  DownloadService(this._repo, {Dio? dio, ConversionService? conversion})
      : _dio = dio ?? Dio(),
        _conversion = conversion ?? ConversionService();

  /// Télécharge une vidéo. Met à jour le repo au fil de l eau.
  /// Retourne true si succès, false si échec (sans throw, pour la file).
  Future<bool> downloadOne(VideoInfo info, StreamOption option) async {
    final base = StorageService.safeFileName(info.title);
    var task = DownloadTask(
      id: info.id, title: info.title, format: option.format,
      status: DownloadStatus.downloading, localPath: null,
      progress: 0, error: null, createdAt: DateTime.now(),
    );
    await _repo.upsert(task);
    try {
      if (option.format == DownloadFormat.mp4) {
        final out = await StorageService.videoPath('$base.mp4');
        await _dio.download(option.url, out,
            onReceiveProgress: (r, t) => _progress(task, r, t));
        task = task.copyWith(status: DownloadStatus.done, localPath: out, progress: 1);
      } else {
        final tmp = await StorageService.tempPath('$base.${option.container}');
        await _dio.download(option.url, tmp,
            onReceiveProgress: (r, t) => _progress(task, r, t));
        await _repo.upsert(task.copyWith(status: DownloadStatus.converting, progress: 1));
        final out = await StorageService.musicPath('$base.mp3');
        final ok = await _conversion.toMp3(
          inputPath: tmp, outputPath: out,
          title: info.title, artist: info.author,
        );
        if (!ok) throw Exception('FFmpeg failed');
        task = task.copyWith(status: DownloadStatus.done, localPath: out, progress: 1);
      }
      await _repo.upsert(task);
      return true;
    } catch (e) {
      await _repo.upsert(task.copyWith(status: DownloadStatus.failed, error: e.toString()));
      return false;
    }
  }

  void _progress(DownloadTask task, int received, int total) {
    if (total <= 0) return;
    _repo.upsert(task.copyWith(progress: received / total));
  }

  /// File séquentielle: skip + log sur échec. Retourne (ok, total).
  Future<(int, int)> downloadPlaylist(
      Stream<VideoInfo> videos, DownloadFormat format) async {
    int ok = 0, total = 0;
    await for (final info in videos) {
      total++;
      final opt = _pickOption(info, format);
      if (opt == null) continue;
      if (await downloadOne(info, opt)) ok++;
    }
    return (ok, total);
  }

  StreamOption? _pickOption(VideoInfo info, DownloadFormat format) {
    final matches = info.options.where((o) => o.format == format);
    return matches.isEmpty ? null : matches.first;
  }
}
