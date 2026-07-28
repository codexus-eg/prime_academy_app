import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String productionBaseUrl = 'https://primeacademy.education/api';

  static const String webDevProxyOrigin = 'http://127.0.0.1:8787';
  static const String webDevProxyBaseUrl = '$webDevProxyOrigin/api';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {

      if (kReleaseMode) return '/api';

      return webDevProxyBaseUrl;
    }

    return productionBaseUrl;
  }

  static const String cdnBaseUrl =
      'https://cdn.primeacademy.education/primeacademy/';

  static String mediaUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$cdnBaseUrl$normalized';
  }
}
