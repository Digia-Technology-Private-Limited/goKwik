import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static SharedPreferences? _prefs;

  // Initialize the SharedPreferences instance once
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> storeSecureData(String key, String value) async {
    try {
      if (_prefs == null) throw Exception('SharedPreferences not initialized');
      await _prefs!.setString(key, value);
    } catch (e) {
      throw Exception('Failed to store data: $e');
    }
  }

  static Future<String?> getSecureData(String key) async {
    try {
      if (_prefs == null) throw Exception('SharedPreferences not initialized');
      return _prefs!.getString(key);
    } catch (e) {
      throw Exception('Failed to get data: $e');
    }
  }

  static Future<void> clearSecureData(String key) async {
    try {
      if (_prefs == null) throw Exception('SharedPreferences not initialized');
      await _prefs!.remove(key);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}
