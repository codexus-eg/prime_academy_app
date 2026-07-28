import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/platform/device_type.dart';
import '../auth/auth_session.dart';

class InquiryException implements Exception {
  InquiryException(this.message, {this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}

abstract final class InquiryService {
  static Future<void> addInquiry({
    required String fullname,
    required String phoneNumber,
    required String content,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/comm-requests/inquiries');

    late final http.Response response;
    try {
      final user = await AuthSession.load();
      response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
          'x-platform': DeviceType.current,
          if (user?.token != null) 'Authorization': 'Bearer ${user!.token}',
        },
        body: jsonEncode({
          'fullname': fullname,
          'phone_number': phoneNumber,
          'content': content,
        }),
      );
    } on http.ClientException catch (error) {
      throw InquiryException(_networkErrorMessage(error.message));
    }

    if (response.statusCode == 200 || response.statusCode == 201) return;

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    final errors = body?['errors'];
    if (errors is Map) {
      final fieldErrors = <String, String>{};
      errors.forEach((key, value) {
        if (key != 'message' && value != null) {
          fieldErrors['$key'] = '$value';
        }
      });
      final message = errors['message'] as String? ??
          'حدث خطأ يرجى المحاولة في وقت لاحق';
      throw InquiryException(
        message,
        fieldErrors: fieldErrors.isEmpty ? null : fieldErrors,
      );
    }

    throw InquiryException(
      body?['message'] as String? ?? 'حدث خطأ يرجى المحاولة في وقت لاحق',
    );
  }

  static String _networkErrorMessage(String details) {
    if (kIsWeb && kDebugMode) {
      return 'تعذّر الاتصال بالخادم. شغّل ./scripts/run_chrome_dev.sh';
    }
    return 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.';
  }
}
