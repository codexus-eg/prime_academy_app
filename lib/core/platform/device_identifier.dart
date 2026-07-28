import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class DeviceIdentifier {
  static const _storageKey = 'device_identifier';

  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _generate();
    await prefs.setString(_storageKey, id);
    return id;
  }

  static String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
