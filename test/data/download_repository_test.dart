import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tubebox/data/download_repository.dart';
import 'package:tubebox/models/download_task.dart';
import 'package:tubebox/models/download_format.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  DownloadTask sample(String id) => DownloadTask(
        id: id, title: 't$id', format: DownloadFormat.mp3,
        status: DownloadStatus.queued, localPath: null,
        progress: 0, error: null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(int.parse(id)),
      );

  test('upsert puis getAll trié par createdAt desc', () async {
    final repo = DownloadRepository();
    await repo.open(inMemory: true);
    await repo.upsert(sample('1'));
    await repo.upsert(sample('2'));
    final all = await repo.getAll();
    expect(all.map((t) => t.id).toList(), ['2', '1']);
  });

  test('upsert met à jour le statut', () async {
    final repo = DownloadRepository();
    await repo.open(inMemory: true);
    await repo.upsert(sample('1'));
    await repo.upsert(sample('1').copyWith(status: DownloadStatus.done));
    final all = await repo.getAll();
    expect(all.single.status, DownloadStatus.done);
  });
}
