import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../network/dio_client.dart';
import '../network/connectivity_service.dart';
import '../storage/app_database.dart';
import '../../features/announcements/data/announcement_model.dart';
import '../../app/providers.dart';

enum SyncStatus { idle, syncing, upToDate, offline, error }

class SyncState {
  final SyncStatus status;
  final int lastVersion;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  SyncState({
    required this.status,
    required this.lastVersion,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? lastVersion,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastVersion: lastVersion ?? this.lastVersion,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncServiceNotifier extends StateNotifier<SyncState> {
  final AppDatabase _dbHelper;
  final DioClient _dioClient;
  final ConnectivityService _connectivity;
  String? _lastEtag;

  SyncServiceNotifier(this._dbHelper, this._dioClient, this._connectivity)
      : super(SyncState(status: SyncStatus.idle, lastVersion: 0)) {
    _initAndStartSync();
  }

  Future<void> _initAndStartSync() async {
    final savedVersion = await _loadSavedVersion();
    state = state.copyWith(lastVersion: savedVersion);

    // Initial background sync
    triggerIncrementalSync(null);

    // Listen to network reconnection
    _connectivity.connectivityStream.listen((isConnected) {
      if (isConnected) {
        triggerIncrementalSync(null);
      } else {
        state = state.copyWith(status: SyncStatus.offline);
      }
    });
  }

  Future<int> _loadSavedVersion() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query('sync_state', where: 'key = ?', whereArgs: ['sync_version']);
      if (rows.isNotEmpty) {
        return int.tryParse(rows.first['value'] as String? ?? '0') ?? 0;
      }
    } catch (e) {
      debugPrint('[SyncService] Error reading saved version: $e');
    }
    return 0;
  }

  Future<void> _saveVersion(int version) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'sync_state',
        {'key': 'sync_version', 'value': version.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[SyncService] Error saving sync version: $e');
    }
  }

  /// Trigger incremental sync without blocking UI
  Future<void> triggerIncrementalSync(dynamic ref) async {
    if (!await _connectivity.hasConnection()) {
      state = state.copyWith(status: SyncStatus.offline);
      return;
    }

    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final response = await _dioClient.getSyncChanges(
        sinceVersion: state.lastVersion,
        etag: _lastEtag,
      );

      // Save HTTP ETag for revalidation
      if (response.headers.value('etag') != null) {
        _lastEtag = response.headers.value('etag');
      }

      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        state = state.copyWith(
          status: SyncStatus.upToDate,
          lastSyncTime: DateTime.now(),
        );
        return;
      }

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final data = response.data;
        final int currentVersion = data['current_version'] ?? state.lastVersion;
        final List<dynamic> changes = data['changes'] ?? [];

        if (changes.isEmpty) {
          state = state.copyWith(
            status: SyncStatus.upToDate,
            lastVersion: currentVersion,
            lastSyncTime: DateTime.now(),
          );
          await _saveVersion(currentVersion);
          return;
        }

        // Track entity categories updated to selectively invalidate Riverpod providers
        final Set<String> updatedEntities = {};

        // Apply changes in an atomic SQLite transaction
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (final change in changes) {
            final String entity = change['entity'] ?? '';
            final String action = change['action'] ?? 'UPDATED';
            final int id = change['id'] ?? 0;
            final Map<String, dynamic> itemData = change['data'] ?? {};

            updatedEntities.add(entity);

            if (entity == 'announcement') {
              if (action == 'DELETED') {
                await txn.delete('announcements', where: 'id = ?', whereArgs: [id]);
              } else {
                final model = AnnouncementModel.fromMap(itemData);
                await txn.insert('announcements', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
              }
            } else if (entity == 'event') {
              if (action == 'DELETED') {
                await txn.delete('events', where: 'id = ?', whereArgs: [id]);
              } else {
                await txn.insert('events', itemData, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            } else if (entity == 'place') {
              if (action == 'DELETED') {
                await txn.delete('places', where: 'id = ?', whereArgs: [id]);
              } else {
                await txn.insert('places', itemData, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            } else if (entity == 'emergency') {
              if (action == 'DELETED') {
                await txn.delete('emergency_facilities', where: 'id = ?', whereArgs: [id]);
              } else {
                await txn.insert('emergency_facilities', itemData, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }
        });

        // ONLY after transaction succeeds, save new sync cursor version!
        await _saveVersion(currentVersion);

        state = state.copyWith(
          status: SyncStatus.upToDate,
          lastVersion: currentVersion,
          lastSyncTime: DateTime.now(),
        );

        // SELECTIVE INVALIDATION: Trigger Riverpod invalidation ONLY for changed entities
        if (ref != null) {
          if (updatedEntities.contains('announcement')) {
            ref.invalidate(announcementsListProvider);
          }
          if (updatedEntities.contains('event')) {
            ref.invalidate(eventsListProvider);
          }
          if (updatedEntities.contains('place')) {
            ref.invalidate(placesListProvider);
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Incremental sync error: $e');
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final syncServiceProvider = StateNotifierProvider<SyncServiceNotifier, SyncState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioClientProvider);
  final conn = ref.watch(connectivityServiceProvider);
  return SyncServiceNotifier(db, dio, conn);
});
