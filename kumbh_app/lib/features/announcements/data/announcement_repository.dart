import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_database.dart';
import 'announcement_model.dart';

abstract class AnnouncementRepository {
  Future<List<AnnouncementModel>> getAnnouncements({String? category});
  Future<void> markAsRead(int id);
}

class HybridAnnouncementRepository implements AnnouncementRepository {
  final AppDatabase _dbHelper;
  final DioClient _dioClient;

  HybridAnnouncementRepository(this._dbHelper, this._dioClient);

  @override
  Future<List<AnnouncementModel>> getAnnouncements({String? category}) async {
    // 1. Read directly from local SQLite database (Populated instantly by SyncService)
    final cached = await _getAnnouncementsFromDb(category: category);
    if (cached.isNotEmpty) {
      return cached;
    }

    // 2. Initial launch fallback if local DB is empty
    try {
      final response = await _dioClient.getAnnouncements();
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        final items = list.map((j) => AnnouncementModel.fromMap(j as Map<String, dynamic>)).toList();
        await _cacheAnnouncements(items);
        return _getAnnouncementsFromDb(category: category);
      }
    } catch (e) {
      debugPrint('[AnnouncementRepository] API initial fetch failed: $e');
    }

    return [];
  }

  Future<List<AnnouncementModel>> _getAnnouncementsFromDb({String? category}) async {
    final db = await _dbHelper.database;
    String sql = "SELECT * FROM announcements WHERE status != 'DELETED'";
    List<dynamic> args = [];

    if (category != null && category != 'All') {
      sql += " AND UPPER(category) = UPPER(?)";
      args.add(category);
    }

    sql += " ORDER BY CASE priority WHEN 'CRITICAL' THEN 1 WHEN 'IMPORTANT' THEN 2 ELSE 3 END, published_at DESC";

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((m) => AnnouncementModel.fromMap(m)).toList();
  }

  Future<void> _cacheAnnouncements(List<AnnouncementModel> items) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      for (final item in items) {
        batch.insert(
          'announcements',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[AnnouncementRepository] Failed to cache announcements: $e');
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'announcements',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[AnnouncementRepository] Failed to mark announcement as read: $e');
    }
  }
}
