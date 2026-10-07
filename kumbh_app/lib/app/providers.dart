import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/app_startup.dart'; // contains globalPrefs
import '../core/storage/app_database.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_service.dart';
import '../core/network/connectivity_service.dart';

import '../features/explore/data/place_model.dart';
import '../features/explore/data/place_repository.dart';
import '../features/events/data/event_model.dart';
import '../features/events/data/event_repository.dart';
import '../features/more/data/contact_model.dart';
import '../features/more/data/contact_repository.dart';
import '../features/more/data/lost_found_report_model.dart';
import '../features/more/data/lost_found_repository.dart';
import '../features/announcements/data/announcement_model.dart';
import '../features/announcements/data/announcement_repository.dart';

import 'dart:async';

// 1. AppDatabase Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// 2. DioClient Provider
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// 3. NetworkService Provider
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

// 4. ConnectivityService Provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// 5. PlaceRepository Provider
final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return SqlitePlaceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioClientProvider),
  );
});

// 6. EventRepository Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return SqliteEventRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioClientProvider),
  );
});

// 7. ContactRepository Provider
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return SqliteContactRepository(ref.watch(appDatabaseProvider));
});

// 8. LostFoundRepository Provider
final lostFoundRepositoryProvider = Provider<LostFoundRepository>((ref) {
  return SqliteLostFoundRepository(ref.watch(appDatabaseProvider));
});

// 9. AnnouncementRepository Provider
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return HybridAnnouncementRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioClientProvider),
  );
});

// 10. Locale Provider & Notifier
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final code = globalPrefs.getString('locale_code') ?? 'en';
    state = Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    await globalPrefs.setString('locale_code', languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

// 11. Contacts Notifier & Provider
class ContactsNotifier extends StateNotifier<List<ContactModel>> {
  final ContactRepository _repo;

  ContactsNotifier(this._repo) : super([]) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    state = await _repo.getContacts();
  }

  Future<void> addContact(String name, String phone) async {
    final contact = ContactModel(name: name, phone: phone);
    await _repo.insertContact(contact);
    await loadContacts();
  }

  Future<void> deleteContact(int id) async {
    await _repo.deleteContact(id);
    await loadContacts();
  }
}

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, List<ContactModel>>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return ContactsNotifier(repo);
});

// 12. Places Filters & Query Providers
final placesSearchQueryProvider = StateProvider<String>((ref) => '');
final placesSelectedCategoryProvider = StateProvider<String>((ref) => 'All');
final placesCrowdFilterProvider = StateProvider<String>((ref) => 'All');
final placesVerifiedOnlyProvider = StateProvider<bool>((ref) => true);

// 13. Places List Provider (recomputes when search/filter provider changes)
final placesListProvider = FutureProvider<List<Place>>((ref) {
  final repo = ref.watch(placeRepositoryProvider);
  final query = ref.watch(placesSearchQueryProvider);
  final category = ref.watch(placesSelectedCategoryProvider);
  final crowdLevel = ref.watch(placesCrowdFilterProvider);
  final verifiedOnly = ref.watch(placesVerifiedOnlyProvider);
  return repo.getPlaces(
    query: query,
    category: category,
    crowdLevel: crowdLevel == 'All' ? null : crowdLevel,
    verifiedOnly: verifiedOnly,
  );
});

// 14. Events by Date Provider (selectedDate + Events by date filtering)
final eventsSelectedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

// 14. Events List Provider
final eventsListProvider = FutureProvider<List<EventModel>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  final selectedDate = ref.watch(eventsSelectedDateProvider);
  return repo.getEvents(date: selectedDate);
});

// 15. Announcements Filter & List Provider
final announcementsCategoryProvider = StateProvider<String>((ref) => 'All');

final announcementsListProvider =
    FutureProvider<List<AnnouncementModel>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  final category = ref.watch(announcementsCategoryProvider);
  return repo.getAnnouncements(category: category);
});

// 16. LostFound Notifier & Provider with Connectivity Auto-Sync
class LostFoundNotifier extends StateNotifier<List<LostFoundReport>> {
  final LostFoundRepository _repo;
  final ConnectivityService _connectivityService;
  final DioClient _dioClient;
  StreamSubscription? _subscription;

  LostFoundNotifier(this._repo, this._connectivityService, this._dioClient)
      : super([]) {
    loadReports();
    _startConnectivitySyncListener();
  }

  Future<void> loadReports() async {
    state = await _repo.getReports();
  }

  Future<void> addReport(LostFoundReport report) async {
    await _repo.insertReport(report);
    await loadReports();
    if (await _connectivityService.hasConnection()) {
      await syncPendingReports();
    }
  }

  void _startConnectivitySyncListener() {
    _subscription =
        _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        syncPendingReports();
      }
    });
  }

  Future<void> syncPendingReports() async {
    final unsynced = await _repo.getUnsyncedReports();
    if (unsynced.isEmpty) return;

    for (final report in unsynced) {
      try {
        final response = await _dioClient.postLostFound(report.toMap());
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (report.id != null) {
            await _repo.markAsSynced(report.id!);
          }
        }
      } catch (e) {
        debugPrint("Failed to sync report ${report.id}: $e");
      }
    }
    await loadReports();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final lostFoundNotifierProvider =
    StateNotifierProvider<LostFoundNotifier, List<LostFoundReport>>((ref) {
  final repo = ref.watch(lostFoundRepositoryProvider);
  final conn = ref.watch(connectivityServiceProvider);
  final dio = ref.watch(dioClientProvider);
  return LostFoundNotifier(repo, conn, dio);
});
