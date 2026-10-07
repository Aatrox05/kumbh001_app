import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/app_database.dart';

// Conditional import: on web, pull in the FFI web factory;
// on native platforms, pull in a stub that does nothing.
import 'db_factory_stub.dart'
    if (dart.library.html) 'db_factory_web.dart' as db_platform;

late final SharedPreferences globalPrefs;

class AppStartup {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ── CRITICAL: Initialize platform-specific database factory BEFORE any
    //    call to getDatabasesPath() or openDatabase().
    //    On Web, sqflite has no default factory – we must set it explicitly.
    //    On Android/iOS/Desktop the standard sqflite factory is auto-configured.
    db_platform.initDatabaseFactory();

    // Initialize SharedPreferences
    globalPrefs = await SharedPreferences.getInstance();

    // Initialize Local SQLite Database (factory is now set for all platforms)
    await AppDatabase().init();
  }
}
