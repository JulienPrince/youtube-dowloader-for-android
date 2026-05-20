import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart';
import '../models/stream_option.dart';
import '../models/download_format.dart';
import 'video_extractor.dart';

class YoutubeExplodeExtractor implements VideoExtractor {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<VideoInfo> extractVideo(String url) async {
    final video = await _yt.videos.get(url);
    // androidVr fournit des URLs téléchargeables sans PoToken (évite le 403) ;
    // android complète avec un flux muxé (MP4 360p). 2 clients = plus rapide.
    final manifest = await _yt.videos.streamsClient.getManifest(
      video.id,
      ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.android],
    );

    final options = <StreamOption>[];
    for (final s in manifest.muxed) {
      options.add(StreamOption(
        format: DownloadFormat.mp4,
        label: s.qualityLabel,
        url: s.url.toString(),
        container: s.container.name,
        sizeBytes: s.size.totalBytes,
        source: s,
      ));
    }
    final audio = manifest.audioOnly.withHighestBitrate();
    options.add(StreamOption(
      format: DownloadFormat.mp3,
      label: 'Audio ${audio.bitrate.kiloBitsPerSecond.round()}kbps',
      url: audio.url.toString(),
      container: audio.container.name,
      bitrate: audio.bitrate.kiloBitsPerSecond.round(),
      sizeBytes: audio.size.totalBytes,
      source: audio,
    ));

    return VideoInfo(
      id: video.id.value,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
      options: options,
    );
  }

  @override
  Future<PlaylistMeta> playlistMeta(String url) async {
    final pl = await _yt.playlists.get(url);
    // videoCount est souvent null côté youtube_explode -> on énumère.
    var count = pl.videoCount ?? 0;
    debugPrint('[PL] "${pl.title}" videoCount=${pl.videoCount}');
    if (count <= 0) {
      count = await _yt.playlists.getVideos(url).length;
      debugPrint('[PL] énuméré -> $count vidéos');
    }
    return PlaylistMeta(pl.title, count);
  }

  @override
  Stream<VideoInfo> extractPlaylist(String url) async* {
    await for (final v in _yt.playlists.getVideos(url)) {
      yield await extractVideo(v.url);
    }
  }

  @override
  Stream<List<int>> readStream(StreamOption option) {
    final info = option.source;
    if (info is! StreamInfo) {
      throw ArgumentError('StreamOption sans StreamInfo youtube_explode');
    }
    // Client natif : requêtes Range segmentées -> plein débit (pas de throttle).
    return _yt.videos.streamsClient.get(info);
  }

  void dispose() => _yt.close();
}
