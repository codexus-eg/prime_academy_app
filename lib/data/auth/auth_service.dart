import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/platform/device_type.dart';
import 'auth_cookie_client.dart';
import 'auth_cookie_parser.dart';
import 'auth_session.dart';
import 'jwt_utils.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class AuthService {
  static var _refreshInFlight = false;

  static Future<AuthUser> loginWithPhone(String identifier) async {
    if (kIsWeb) {
      return _loginWithHttpPackage(identifier);
    }
    return _loginWithNativeClient(identifier);
  }

  static Future<AuthUser> _loginWithNativeClient(String identifier) async {
    try {
      final result = await AuthCookieClient.login(identifier: identifier);
      return _userFromLoginResult(result);
    } on AuthLoginNetworkException catch (error) {
      throw AuthException(_networkErrorMessage(error.message));
    }
  }

  static Future<AuthUser> _loginWithHttpPackage(String identifier) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    late final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
        },
        body: jsonEncode({
          'identifier': identifier,
          'deviceType': DeviceType.current,
        }),
      );
    } on http.ClientException catch (error) {
      throw AuthException(_networkErrorMessage(error.message));
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      body = null;
    }

    if (response.statusCode != 200) {
      throw AuthException(_messageFromBody(body));
    }

    try {
      final user = AuthUser.fromJson(body!);
      final refreshToken = AuthCookieParser.readCookieFromCombinedHeader(
        response.headers['set-cookie'],
        'refreshToken',
      );
      await AuthSession.save(user, refreshToken: refreshToken);
      return user;
    } catch (_) {
      throw AuthException('استجابة غير متوقعة من الخادم');
    }
  }

  static Future<AuthUser> _userFromLoginResult(AuthLoginNetworkResult result) async {
    if (result.statusCode != 200) {
      throw AuthException(_messageFromBody(result.body));
    }

    try {
      final user = AuthUser.fromJson(result.body!);
      await AuthSession.save(
        user,
        refreshToken: result.refreshToken,
      );
      return user;
    } catch (_) {
      throw AuthException('استجابة غير متوقعة من الخادم');
    }
  }

  static Future<bool> ensureFreshAccessToken() async {
    final user = await AuthSession.load();
    if (user == null) return false;

    if (!JwtUtils.isExpired(user.token)) return true;
    return tryRefreshSession();
  }

  static Future<bool> restoreSession() async {
    if (!await AuthSession.isRestorable()) {
      await AuthSession.clear();
      return false;
    }
    return ensureFreshAccessToken();
  }

  static Future<bool> tryRefreshSession() async {
    if (_refreshInFlight) return false;
    _refreshInFlight = true;
    try {
      final user = await AuthSession.load();
      final refreshToken = await AuthSession.loadRefreshToken();
      if (user == null || refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      if (JwtUtils.isExpired(refreshToken)) {
        await AuthSession.clear();
        return false;
      }

      if (kIsWeb) {
        return _refreshOnWeb(user, refreshToken);
      }

      final result = await AuthCookieClient.refreshSession(
        refreshToken: refreshToken,
        expiredAccessToken: user.token,
      );
      if (result == null) return false;

      await AuthSession.save(
        user.copyWith(token: result.accessToken),
        refreshToken: result.refreshToken ?? refreshToken,
      );
      return true;
    } finally {
      _refreshInFlight = false;
    }
  }

  static Future<bool> _refreshOnWeb(AuthUser user, String refreshToken) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/students/my-profile');
    late final http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'ar',
          'x-platform': DeviceType.current,
          'Authorization': 'Bearer ${user.token}',
          'Cookie': 'refreshToken=$refreshToken',
        },
      );
    } catch (_) {
      return false;
    }

    if (response.statusCode != 200) return false;

    final newAccess = AuthCookieParser.readCookieFromCombinedHeader(
          response.headers['set-cookie'],
          'accessToken',
        ) ??
        user.token;

    final newRefresh = AuthCookieParser.readCookieFromCombinedHeader(
          response.headers['set-cookie'],
          'refreshToken',
        ) ??
        refreshToken;

    await AuthSession.save(
      user.copyWith(token: newAccess),
      refreshToken: newRefresh,
    );
    return true;
  }

  static Future<void> logout() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
    try {
      final user = await AuthSession.load();
      final refreshToken = await AuthSession.loadRefreshToken();
      await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
          'x-platform': DeviceType.current,
          if (user?.token != null) 'Authorization': 'Bearer ${user!.token}',
          if (refreshToken != null) 'Cookie': 'refreshToken=$refreshToken',
        },
      );
    } catch (_) {

    } finally {
      await AuthSession.clear();
    }
  }

  static Future<void> deleteMyAccount() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/my-account');
    final user = await AuthSession.load();
    final refreshToken = await AuthSession.loadRefreshToken();
    if (user?.token == null) {
      throw AuthException('يجب تسجيل الدخول أولاً');
    }

    late final http.Response response;
    try {
      response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
          'x-platform': DeviceType.current,
          'Authorization': 'Bearer ${user!.token}',
          if (refreshToken != null) 'Cookie': 'refreshToken=$refreshToken',
        },
      );
    } on http.ClientException catch (error) {
      throw AuthException(_networkErrorMessage(error.message));
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        body = null;
      }
      throw AuthException(_messageFromBody(body));
    }

    await AuthSession.clear();
  }

  static String _messageFromBody(Map<String, dynamic>? body) {
    final errors = body?['errors'];
    if (errors is Map && errors['message'] is String) {
      return errors['message'] as String;
    }
    return body?['message'] as String? ?? 'البيانات المدخلة غير صحيحة';
  }

  static String _networkErrorMessage(String details) {
    if (kIsWeb) {
      return 'تعذّر الاتصال بالخادم. شغّل ./scripts/run_chrome_dev.sh';
    }
    return 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.';
  }
}
