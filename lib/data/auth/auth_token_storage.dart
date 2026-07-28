import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AuthTokenStorage {
  static const _userKey = 'auth_user';
  static const _refreshKey = 'auth_refresh_token';
  static const _legacyPrefsUserKey = 'auth_user';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> writeUser(String json) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json);
      return;
    }

    await _secureStorage.write(key: _userKey, value: json);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPrefsUserKey);
  }

  static Future<String?> readUser() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userKey);
    }

    final secureValue = await _secureStorage.read(key: _userKey);
    if (secureValue != null) return secureValue;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyPrefsUserKey);
    if (legacy != null) {
      await _secureStorage.write(key: _userKey, value: legacy);
      await prefs.remove(_legacyPrefsUserKey);
    }
    return legacy;
  }

  static Future<void> writeRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshKey, token);
      return;
    }
    await _secureStorage.write(key: _refreshKey, value: token);
  }

  static Future<String?> readRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshKey);
    }
    return _secureStorage.read(key: _refreshKey);
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_refreshKey);
      await prefs.remove(_legacyPrefsUserKey);
      return;
    }

    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _refreshKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPrefsUserKey);
  }
}
