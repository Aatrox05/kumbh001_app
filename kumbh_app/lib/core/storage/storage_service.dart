import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<bool> setString(String key, String value) async {
    final p = await _instance;
    return p.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final p = await _instance;
    return p.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    final p = await _instance;
    return p.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final p = await _instance;
    return p.getBool(key);
  }

  static Future<bool> remove(String key) async {
    final p = await _instance;
    return p.remove(key);
  }
}
