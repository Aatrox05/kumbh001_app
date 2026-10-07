import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_tables.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  Database? _database;

  Database get db {
    if (_database == null) {
      throw StateError("Database is not initialized. Call AppDatabase().init() first.");
    }
    return _database!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  Future<void> init() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kumbh_mela.db');

    _database = await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Places table
    await db.execute('''
      CREATE TABLE ${DbTables.places} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image_url TEXT,
        distance_km REAL,
        crowd_level TEXT,
        category TEXT,
        description TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        opening_hours TEXT,
        is_verified INTEGER DEFAULT 1
      )
    ''');

    // 2. Events table
    await db.execute('''
      CREATE TABLE ${DbTables.events} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        location_name TEXT,
        start_time TEXT,
        end_time TEXT,
        audio_url TEXT,
        description TEXT,
        image_url TEXT,
        category TEXT,
        latitude REAL,
        longitude REAL,
        organizer TEXT,
        is_verified INTEGER DEFAULT 1
      )
    ''');

    // 3. Announcements table — includes status column for soft-delete support
    await db.execute('''
      CREATE TABLE ${DbTables.announcements} (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        priority TEXT DEFAULT 'NORMAL',
        category TEXT DEFAULT 'GENERAL',
        target_group TEXT DEFAULT 'ALL',
        published_at TEXT,
        expires_at TEXT,
        source_name TEXT,
        version INTEGER DEFAULT 1,
        is_read INTEGER DEFAULT 0,
        status TEXT DEFAULT 'ACTIVE'
      )
    ''');

    // 4. Emergency Contacts table
    await db.execute('''
      CREATE TABLE ${DbTables.contacts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        type TEXT DEFAULT 'PERSONAL'
      )
    ''');

    // 5. Lost & Found reports table — includes image_base64 for photo upload
    await db.execute('''
      CREATE TABLE ${DbTables.lostFound} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        location TEXT,
        contact TEXT,
        description TEXT,
        is_lost INTEGER,
        image_base64 TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // 6. Emergency Facilities table
    await db.execute('''
      CREATE TABLE emergency_facilities (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        phone TEXT NOT NULL,
        secondary_phone TEXT,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        capacity INTEGER,
        current_status TEXT
      )
    ''');

    // 7. Sync State table
    await db.execute('''
      CREATE TABLE sync_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Full recreation on any version upgrade for simplicity during development
    await db.execute('DROP TABLE IF EXISTS places');
    await db.execute('DROP TABLE IF EXISTS events');
    await db.execute('DROP TABLE IF EXISTS announcements');
    await db.execute('DROP TABLE IF EXISTS contacts');
    await db.execute('DROP TABLE IF EXISTS lost_found_reports');
    await db.execute('DROP TABLE IF EXISTS ${DbTables.lostFound}');
    await db.execute('DROP TABLE IF EXISTS emergency_facilities');
    await db.execute('DROP TABLE IF EXISTS sync_state');
    await _onCreate(db, newVersion);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
