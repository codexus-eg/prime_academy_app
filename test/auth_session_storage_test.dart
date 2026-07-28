import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/data/auth/auth_cookie_parser.dart';
import 'package:prime_flutter/data/auth/jwt_utils.dart';

void main() {
  group('JwtUtils', () {
    test('reads expiration from JWT payload', () {
      final token = _jwt(exp: 1_700_000_000);
      final expiresAt = JwtUtils.expirationDate(token);
      expect(expiresAt, isNotNull);
      expect(expiresAt!.toUtc().millisecondsSinceEpoch, 1_700_000_000 * 1000);
    });

    test('detects expired token with leeway', () {
      final pastExp =
          DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000;
      final past = _jwt(exp: pastExp);
      expect(JwtUtils.isExpired(past), isTrue);
    });
  });

  group('AuthCookieParser', () {
    test('extracts refreshToken from set-cookie header', () {
      const header =
          'refreshToken=abc.def.ghi; Path=/; Expires=Wed, 21 Oct 2026 07:28:00 GMT';
      expect(
        AuthCookieParser.readCookieFromCombinedHeader(header, 'refreshToken'),
        'abc.def.ghi',
      );
    });
  });
}

String _jwt({required int exp}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode('{"exp":$exp}'));
  return '$header.$payload.signature';
}
