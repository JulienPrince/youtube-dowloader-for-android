import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class ConversionService {
  /// Transcode [inputPath] (m4a/webm) vers [outputPath] (.mp3),
  /// injecte titre/artiste et la pochette [thumbnailPath].
  Future<bool> toMp3({
    required String inputPath,
    required String outputPath,
    required String title,
    required String artist,
    String? thumbnailPath,
  }) async {
    // executeWithArguments passe chaque argument tel quel : pas de parsing
    // shell, donc des titres avec espaces ou guillemets ne cassent rien.
    final args = <String>[
      '-y', '-i', inputPath,
      if (thumbnailPath != null) ...['-i', thumbnailPath],
      '-vn',
      if (thumbnailPath != null) ...[
        '-map', '0:a', '-map', '1:0', '-id3v2_version', '3',
        '-metadata:s:v', 'title=Album cover',
        '-metadata:s:v', 'comment=Cover (front)',
      ] else ...[
        '-map', '0:a',
      ],
      '-c:a', 'libmp3lame', '-q:a', '2',
      '-metadata', 'title=$title',
      '-metadata', 'artist=$artist',
      outputPath,
    ];
    final session = await FFmpegKit.executeWithArguments(args);
    final rc = await session.getReturnCode();
    return ReturnCode.isSuccess(rc);
  }
}
