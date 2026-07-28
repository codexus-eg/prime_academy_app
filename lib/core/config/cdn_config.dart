import 'package:flutter/foundation.dart';

abstract final class CdnConfig {
  static const String productionStaticBaseUrl =
      'https://cdn-statics.primeacademy.education/';
  static const String webDevStaticProxyBaseUrl =
      'http://127.0.0.1:8787/cdn-statics/';
  static const String productionMediaBaseUrl =
      'https://cdn.primeacademy.education/primeacademy/';
  static const String webDevMediaProxyBaseUrl =
      'http://127.0.0.1:8787/cdn-media/';

  static String get staticBaseUrl {
    if (kIsWeb && kDebugMode) return webDevStaticProxyBaseUrl;
    return productionStaticBaseUrl;
  }

  static String get mediaBaseUrl {
    if (kIsWeb && kDebugMode) return webDevMediaProxyBaseUrl;
    return productionMediaBaseUrl;
  }

  static String staticUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$staticBaseUrl$path';
  }

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    if (kIsWeb && kDebugMode) {
      const prodPrefixes = [
        'https://cdn.primeacademy.education/primeacademy/',
        'https://cdn.primeacademy.education/primeacademy',
        'http://cdn.primeacademy.education/primeacademy/',
      ];
      for (final prefix in prodPrefixes) {
        if (path.startsWith(prefix)) {
          var rest = path.substring(prefix.length);
          if (rest.startsWith('/')) rest = rest.substring(1);
          return '$webDevMediaProxyBaseUrl$rest';
        }
      }
    }

    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    var normalized = path.startsWith('/') ? path.substring(1) : path;
    const prefix = 'primeacademy/';
    if (normalized.startsWith(prefix)) {
      normalized = normalized.substring(prefix.length);
    }
    return '$mediaBaseUrl$normalized';
  }
}
