import 'package:flutter_test/flutter_test.dart';
import 'package:tubebox/models/download_task.dart';
import 'package:tubebox/models/download_format.dart';

void main() {
  test('toMap / fromMap round-trip', () {
    final t = DownloadTask(
      id: 'abc',
      title: 'Ma vidéo',
      format: DownloadFormat.mp3,
      status: DownloadStatus.downloading,
      localPath: null,
      progress: 0.5,
      error: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    final back = DownloadTask.fromMap(t.toMap());
    expect(back.id, 'abc');
    expect(back.format, DownloadFormat.mp3);
    expect(back.status, DownloadStatus.downloading);
    expect(back.progress, 0.5);
    expect(back.createdAt, t.createdAt);
  });
}
