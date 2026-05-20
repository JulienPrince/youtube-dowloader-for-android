import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/download_task.dart';

class DownloadRepository {
  late Database _db;
  static int _counter = 0;

  Future<void> open({bool inMemory = false}) async {
    final path = inMemory
        ? '${inMemoryDatabasePath}_${_counter++}'
        : p.join(await getDatabasesPath(), 'downloads.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE downloads(
          id TEXT PRIMARY KEY, title TEXT, format TEXT, status TEXT,
          localPath TEXT, progress REAL, error TEXT, createdAt INTEGER
        )'''),
    );
  }

  Future<void> upsert(DownloadTask t) => _db.insert(
        'downloads', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<DownloadTask>> getAll() async {
    final rows = await _db.query('downloads', orderBy: 'createdAt DESC');
    return rows.map(DownloadTask.fromMap).toList();
  }

  Future<void> delete(String id) =>
      _db.delete('downloads', where: 'id = ?', whereArgs: [id]);

  Future<void> clearAll() => _db.delete('downloads');

  /// Au démarrage : un téléchargement non terminé vient d'un process tué
  /// (il ne reprendra pas). On le marque en échec pour vider "En cours".
  Future<void> failStale() => _db.update(
        'downloads',
        {'status': 'failed', 'error': 'Interrompu'},
        where: 'status IN (?, ?, ?)',
        whereArgs: ['queued', 'downloading', 'converting'],
      );
}
