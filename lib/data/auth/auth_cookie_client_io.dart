import 'dart:convert';
import 'dart:io';

import '../../core/config/api_config.dart';
import '../../core/platform/device_type.dart';
import 'auth_cookie_parser.dart';
import 'auth_cookie_types.dart';

abstract final class AuthCookieClient {
  static Future<AuthLoginNetworkResult> login({
    required String identifier,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/v2/login');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.headers.set('Accept-Language', 'ar');
      request.write(jsonEncode({
        'identifier': identifier,
        'deviceType': DeviceType.current,
      }));

      final response = await request.close();
      final rawBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        body = null;
      }

      final cookies = cookiesFromLoginResponse(response);

      return AuthLoginNetworkResult(
        statusCode: response.statusCode,
        body: body,
        refreshToken: cookies['refreshToken'],
        accessTokenFromCookie: cookies['accessToken'],
      );
    } on SocketException catch (error) {
      throw AuthLoginNetworkException(error.message);
    } on HttpException catch (error) {
      throw AuthLoginNetworkException(error.message);
    } catch (error) {
      if (error is AuthLoginNetworkException) rethrow;
      throw AuthLoginNetworkException(error.toString());
    } finally {
      client.close(force: true);
    }
  }

  static Future<AuthCookieRefreshResult?> refreshSession({
    required String refreshToken,
    String? expiredAccessToken,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/students/my-profile');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      request.headers.set('Accept-Language', 'ar');
      request.headers.set('x-platform', DeviceType.current);
      request.cookies.add(Cookie('refreshToken', refreshToken));
      if (expiredAccessToken != null && expiredAccessToken.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $expiredAccessToken');
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return null;

      final cookies = cookiesFromLoginResponse(response);
      var newAccess = cookies['accessToken'];
      newAccess ??= _readTokenFromBody(body);
      if (newAccess == null || newAccess.isEmpty) return null;

      return AuthCookieRefreshResult(
        accessToken: newAccess,
        refreshToken: cookies['refreshToken'],
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static String? _readTokenFromBody(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final token = json['token'];
        if (token is String && token.isNotEmpty) return token;
      }
    } catch (_) {

    }
    return null;
  }

  static List<String> setCookieHeaders(HttpClientResponse response) {
    return response.headers['set-cookie'] ?? const [];
  }

  static Map<String, String> cookiesFromLoginResponse(HttpClientResponse response) {
    final values = <String, String>{};
    for (final cookie in response.cookies) {
      if (cookie.value.isNotEmpty) {
        values[cookie.name] = cookie.value;
      }
    }

    for (final header in setCookieHeaders(response)) {
      for (final name in ['refreshToken', 'accessToken']) {
        final parsed = AuthCookieParser.readCookieFromCombinedHeader(header, name);
        if (parsed != null && parsed.isNotEmpty) {
          values.putIfAbsent(name, () => parsed);
        }
      }
    }

    return values;
  }
}
