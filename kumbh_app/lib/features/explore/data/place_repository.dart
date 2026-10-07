import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_database.dart';
import 'place_model.dart';

abstract class PlaceRepository {
  Future<List<Place>> getPlaces({
    String? query,
    String? category,
    String? crowdLevel,
    bool? verifiedOnly,
  });
}

class HybridPlaceRepository implements PlaceRepository {
  final AppDatabase _dbHelper;
  final DioClient _dioClient;

  HybridPlaceRepository(this._dbHelper, this._dioClient);

  @override
  Future<List<Place>> getPlaces({
    String? query,
    String? category,
    String? crowdLevel,
    bool? verifiedOnly,
  }) async {
    // 1. Read directly from local SQLite (SyncService keeps SQLite in sync)
    final cached = await _getPlacesFromLocalDb(
      query: query,
      category: category,
      crowdLevel: crowdLevel,
      verifiedOnly: verifiedOnly ?? true,
    );
    if (cached.isNotEmpty) {
      return cached;
    }

    // 2. Initial launch fallback if local SQLite is empty
    try {
      final response = await _dioClient.getPlaces(category: category, query: query);
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        final places = list.map((json) => Place.fromMap(json as Map<String, dynamic>)).toList();
        await _cachePlaces(places);
        return _getPlacesFromLocalDb(
          query: query,
          category: category,
          crowdLevel: crowdLevel,
          verifiedOnly: verifiedOnly ?? true,
        );
      }
    } catch (e) {
      debugPrint('[PlaceRepository] API initial fetch failed: $e');
    }

    return [];
  }

  Future<List<Place>> _getPlacesFromLocalDb({
    String? query,
    String? category,
    String? crowdLevel,
    bool verifiedOnly = true,
  }) async {
    final db = await _dbHelper.database;
    String sql = 'SELECT * FROM places WHERE 1=1';
    List<dynamic> arguments = [];

    if (verifiedOnly) {
      sql += ' AND is_verified = 1';
    }

    if (category != null && category != 'All') {
      sql += ' AND UPPER(category) = UPPER(?)';
      arguments.add(category);
    }

    if (crowdLevel != null && crowdLevel.isNotEmpty && crowdLevel != 'All') {
      sql += ' AND UPPER(crowd_level) = UPPER(?)';
      arguments.add(crowdLevel);
    }

    if (query != null && query.isNotEmpty) {
      sql += ' AND (name LIKE ? OR description LIKE ?)';
      arguments.add('%$query%');
      arguments.add('%$query%');
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, arguments);
    return maps.map((m) => Place.fromMap(m)).toList();
  }

  Future<void> _cachePlaces(List<Place> places) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      for (final place in places) {
        batch.insert(
          'places',
          place.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[PlaceRepository] Failed to cache places in SQLite: $e');
    }
  }
}

typedef SqlitePlaceRepository = HybridPlaceRepository;
