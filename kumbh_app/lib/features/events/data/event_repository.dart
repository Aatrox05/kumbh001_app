import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_database.dart';
import 'event_model.dart';

abstract class EventRepository {
  Future<List<EventModel>> getEvents({String? category, DateTime? date});
}

class HybridEventRepository implements EventRepository {
  final AppDatabase _dbHelper;
  final DioClient _dioClient;

  HybridEventRepository(this._dbHelper, this._dioClient);

  @override
  Future<List<EventModel>> getEvents({String? category, DateTime? date}) async {
    // 1. Fetch fresh events from backend API
    try {
      final response = await _dioClient.getEvents(category: category);
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        final events = list.map((json) => EventModel.fromMap(json as Map<String, dynamic>)).toList();

        // 2. Cache in SQLite background
        _cacheEvents(events);
        return _filterByDate(events, date);
      }
    } catch (e) {
      debugPrint('[EventRepository] API offline or error, falling back to local SQLite cache: $e');
    }

    // 3. Fallback to local SQLite database
    return _getEventsFromLocalDb(category: category, date: date);
  }

  List<EventModel> _filterByDate(List<EventModel> events, DateTime? date) {
    if (date == null) return events;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return events.where((e) {
      final start = e.startTime;
      if (start.isEmpty) return true;
      return start.startsWith(dateStr) || start.contains(dateStr);
    }).toList();
  }

  Future<List<EventModel>> _getEventsFromLocalDb({String? category, DateTime? date}) async {
    final db = await _dbHelper.database;
    String sql = 'SELECT * FROM events WHERE 1=1';
    List<dynamic> arguments = [];

    if (category != null && category != 'All') {
      sql += ' AND UPPER(category) = UPPER(?)';
      arguments.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, arguments);
    final all = maps.map((m) => EventModel.fromMap(m)).toList();
    return _filterByDate(all, date);
  }

  Future<void> _cacheEvents(List<EventModel> events) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      for (final event in events) {
        batch.insert(
          'events',
          event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[EventRepository] Failed to cache events in SQLite: $e');
    }
  }
}

// Alias for backwards compatibility
typedef SqliteEventRepository = HybridEventRepository;
