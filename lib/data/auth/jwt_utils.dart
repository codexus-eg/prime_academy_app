import 'dart:convert';

abstract final class JwtUtils {
  static DateTime? expirationDate(String token) {
    final payload = _decodePayload(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true).toLocal();
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true)
          .toLocal();
    }
    return null;
  }

  static bool isExpired(String token, {Duration leeway = const Duration(minutes: 2)}) {
    final expiresAt = expirationDate(token);
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt.subtract(leeway));
  }

  static Map<String, dynamic>? _decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }
}
