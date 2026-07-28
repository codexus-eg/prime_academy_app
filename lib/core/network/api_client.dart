import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../platform/device_type.dart';
import '../../data/auth/auth_service.dart';
import '../../data/auth/auth_session.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract final class ApiClient {
  static Future<Map<String, String>> authHeaders() async {
    final user = await AuthSession.load();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar',
      'x-platform': DeviceType.current,
      if (user?.token != null) 'Authorization': 'Bearer ${user!.token}',
    };
  }

  static Future<Map<String, dynamic>> getJson(String path) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.get(uri, headers: await authHeaders());
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      return _decodeResponse(response);
    });
  }

  static Future<void> patchJson(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.patch(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        );
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        Map<String, dynamic>? decoded;
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) decoded = raw;
        } catch (_) {
          decoded = null;
        }

        final errors = decoded?['errors'];
        if (errors is Map && errors['message'] is String) {
          throw ApiException(
            errors['message'] as String,
            statusCode: response.statusCode,
          );
        }
        throw ApiException(
          decoded?['message'] as String? ?? 'حدث خطأ أثناء تحميل البيانات',
          statusCode: response.statusCode,
        );
      }
    });
  }

  static Future<Map<String, dynamic>> patchJsonMap(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.patch(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        );
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      return _decodeResponse(response);
    });
  }

  static Future<Map<String, dynamic>> postJson(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.post(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        );
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      return _decodeResponse(response);
    });
  }

  static Future<List<int>> postBytes(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.post(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        );
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      if (response.statusCode != 200) {
        throw ApiException(
          'تعذّر تحميل التقرير',
          statusCode: response.statusCode,
        );
      }

      return response.bodyBytes;
    });
  }

  static Future<void> postVoid(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.post(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        );
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw ApiException(
          _errorMessageFromResponse(
            response,
            fallback: 'حدث خطأ أثناء تحميل البيانات',
          ),
          statusCode: response.statusCode,
        );
      }
    });
  }

  static String _errorMessageFromResponse(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return fallback;

      final errors = decoded['errors'];
      if (errors is Map && errors['message'] is String) {
        return errors['message'] as String;
      }

      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final details = decoded['details'];
      if (details is String && details.trim().isNotEmpty) {
        return details;
      }
    } catch (_) {

    }
    return fallback;
  }

  static Future<void> deleteVoid(String path) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.delete(uri, headers: await authHeaders());
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'حدث خطأ أثناء تحميل البيانات',
          statusCode: response.statusCode,
        );
      }
    });
  }

  static Future<List<dynamic>> getJsonList(String path) {
    return _withAuthRefresh(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      late final http.Response response;

      try {
        response = await http.get(uri, headers: await authHeaders());
      } on http.ClientException catch (error) {
        throw ApiException(_networkErrorMessage(error.message));
      }

      if (response.statusCode != 200) {
        throw ApiException(
          'حدث خطأ أثناء تحميل البيانات',
          statusCode: response.statusCode,
        );
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      } catch (_) {

      }
      throw ApiException('استجابة غير متوقعة من الخادم');
    });
  }

  static Future<T> _withAuthRefresh<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      if (!_isAuthFailure(error.statusCode)) rethrow;

      final refreshed = await AuthService.tryRefreshSession();
      if (!refreshed) {
        await AuthSession.clear();
        rethrow;
      }

      return request();
    }
  }

  static bool _isAuthFailure(int? statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    if (!_isSuccessStatus(response.statusCode)) {
      final errors = body?['errors'];
      if (errors is Map && errors['message'] is String) {
        throw ApiException(errors['message'] as String, statusCode: response.statusCode);
      }
      throw ApiException(
        body?['message'] as String? ?? 'حدث خطأ أثناء تحميل البيانات',
        statusCode: response.statusCode,
      );
    }

    if (body == null) {
      throw ApiException('استجابة غير متوقعة من الخادم');
    }

    return body;
  }

  static bool _isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static String _networkErrorMessage(String details) {
    if (kIsWeb && kDebugMode) {
      return 'تعذّر الاتصال بالخادم. شغّل ./scripts/run_chrome_dev.sh';
    }
    return 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.';
  }
}
