import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class KwikPassCache {
  final _storage = const FlutterSecureStorage();
  final Map<String, String?> _cache = {};

  static const _userIdKey = 'gkSnowplowUserId';
  static const _timestampKey = 'gkSnowplowUserIdTimestamp';

  Future<String?> getValue(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        _cache[key] = value;
        return value;
      }
      return null;
    } catch (e) {
      print('Error fetching key $key: $e');
      return null;
    }
  }

  Future<void> setValue(String key, String value) async {
    _cache[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('Error storing key $key: $e');
    }
  }

  void clearCache() {
    _cache.clear();
  }

  Future<void> removeValue(String key) async {
    _cache.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('Error removing key $key: $e');
    }
  }

  Future<void> setSnowplowUserId(String userId) async {
    final timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss").format(DateTime.now());
    _cache[_userIdKey] = userId;
    _cache[_timestampKey] = timestamp;

    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _timestampKey, value: timestamp);
  }

  String? getSnowplowUserId() {
    final userId = _cache[_userIdKey];
    final timestamp = _cache[_timestampKey];

    if (userId == null || timestamp == null) return null;

    final storedTime = DateTime.tryParse(timestamp);
    if (storedTime == null) return null;

    final currentTime = DateTime.now();
    if (currentTime.difference(storedTime).inHours > 24) {
      return null;
    }

    return userId;
  }

  Future<String?> getStoredSnowplowUserId() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      final timestamp = await _storage.read(key: _timestampKey);

      if (userId == null || timestamp == null) return null;

      final storedTime = DateTime.tryParse(timestamp);
      if (storedTime == null) return null;

      if (DateTime.now().difference(storedTime).inHours > 24) {
        return null;
      }

      return userId;
    } catch (e) {
      print('Error getting stored Snowplow user ID: $e');
      return null;
    }
  }
}

// Singleton instance
final cacheInstance = KwikPassCache();
