import '../../../core/storage/app_database.dart';
import 'lost_found_report_model.dart';

abstract class LostFoundRepository {
  Future<List<LostFoundReport>> getReports();
  Future<List<LostFoundReport>> getUnsyncedReports();
  Future<int> insertReport(LostFoundReport report);
  Future<int> markAsSynced(int id);
}

class SqliteLostFoundRepository implements LostFoundRepository {
  final AppDatabase _dbHelper;

  SqliteLostFoundRepository(this._dbHelper);

  @override
  Future<List<LostFoundReport>> getReports() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('lost_found_reports');
    return List.generate(maps.length, (i) => LostFoundReport.fromMap(maps[i]));
  }

  @override
  Future<List<LostFoundReport>> getUnsyncedReports() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lost_found_reports',
      where: 'synced = 0',
    );
    return List.generate(maps.length, (i) => LostFoundReport.fromMap(maps[i]));
  }

  @override
  Future<int> insertReport(LostFoundReport report) async {
    final db = await _dbHelper.database;
    return await db.insert('lost_found_reports', report.toMap());
  }

  @override
  Future<int> markAsSynced(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'lost_found_reports',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
