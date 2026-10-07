import 'package:kumbh_app/core/storage/app_database.dart';
import 'package:kumbh_app/core/storage/db_tables.dart';
import '../../domain/repositories/lost_found_repository.dart';
import '../models/lost_found_report.dart';

class SqliteLostFoundRepository implements LostFoundRepository {
  @override
  Future<int> insertReport(LostFoundReport report) async {
    final db = AppDatabase().db;
    return db.insert(
      DbTables.lostFound,
      report.toMap(),
    );
  }

  @override
  Future<List<LostFoundReport>> getUnsyncedReports() async {
    final db = AppDatabase().db;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.lostFound,
      where: '${DbTables.lostFoundSynced} = 0',
    );
    return maps.map((m) => LostFoundReport.fromMap(m)).toList();
  }

  @override
  Future<void> markAsSynced(int id) async {
    final db = AppDatabase().db;
    await db.update(
      DbTables.lostFound,
      {DbTables.lostFoundSynced: 1},
      where: '${DbTables.lostFoundId} = ?',
      whereArgs: [id],
    );
  }
}
