import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/download_repository.dart';
import '../extractor/video_extractor.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import 'storage_service.dart';
import 'conversion_service.dart';

class DownloadService {
  final DownloadRepository _repo;
  final VideoExtractor _extractor;
  final Dio _dio; // miniature uniquement (i.ytimg.com, pas throttlé)
  final ConversionService _conversion;

  DownloadService(this._repo, this._extractor,
      {Dio? dio, ConversionService? conversion})
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
        await _writeStream(option, out, task);
        task = task.copyWith(status: DownloadStatus.done, localPath: out, progress: 1);
      } else {
        final tmp = await StorageService.tempPath('$base.${option.container}');
        String? thumb;
        await _writeStream(option, tmp, task);
        await _repo.upsert(task.copyWith(status: DownloadStatus.converting, progress: 1));
        final out = await StorageService.musicPath('$base.mp3');
        try {
          if (info.thumbnailUrl.isNotEmpty) {
            thumb = await StorageService.tempPath('$base.cover.jpg');
            try {
              await _dio.download(info.thumbnailUrl, thumb);
            } catch (_) {
              thumb = null; // pochette best-effort
            }
          }
          final ok = await _conversion.toMp3(
            inputPath: tmp, outputPath: out,
            title: info.title, artist: info.author,
            thumbnailPath: thumb,
          );
          if (!ok) throw Exception('FFmpeg failed');
        } finally {
          await _deleteQuietly(tmp);
          if (thumb != null) await _deleteQuietly(thumb);
        }
        task = task.copyWith(status: DownloadStatus.done, localPath: out, progress: 1);
      }
      await _repo.upsert(task);
      return true;
    } catch (e) {
      debugPrint('[DL] FAIL "${info.title}": $e');
      await _repo.upsert(task.copyWith(status: DownloadStatus.failed, error: e.toString()));
      return false;
    }
  }

  /// Écrit le flux dans [path] via le client de l'extracteur (débit plein,
  /// pas de throttling). Progression throttlée à chaque % entier.
  Future<void> _writeStream(
      StreamOption option, String path, DownloadTask task) async {
    final sink = File(path).openWrite();
    final total = option.sizeBytes ?? 0;
    var received = 0;
    var lastPct = -1;
    try {
      await for (final chunk in _extractor.readStream(option)) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final pct = received * 100 ~/ total;
          if (pct != lastPct) {
            lastPct = pct;
            await _repo.upsert(task.copyWith(progress: received / total));
          }
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
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
