import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web implementation: sets the global databaseFactory to the FFI web
/// no-web-worker variant. This runs SQLite via WASM in the main thread
/// and requires only sqlite3.wasm in the web/ folder (no sqflite_sw.js needed).
///
/// Persistence is backed by IndexedDB in the browser.
void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
