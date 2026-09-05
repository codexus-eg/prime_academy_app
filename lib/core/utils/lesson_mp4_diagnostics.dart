import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Diagnostics for Prime Academy progressive CDN MP4 (no DRM).
///
/// Logs the final URL, response headers, and classifies failures so the UI
/// never shows a "decrypt" message unless the failure is actually codec/DRM.
abstract final class LessonMp4Diagnostics {
  /// Pass the CDN URL unchanged (no re-encode). Only trim whitespace.
  static String playbackUrl(String url) => url.trim();

  static Uri playbackUri(String url) => Uri.parse(playbackUrl(url));

  /// HEAD probe — mirrors what the browser receives before `<video>` plays.
  static Future<LessonMp4ProbeResult> probe(String url) async {
    final uri = playbackUri(url);
    try {
      final response = await http
          .head(uri)
          .timeout(const Duration(seconds: 20));
      final headers = <String, String>{};
      response.headers.forEach((key, value) {
        headers[key.toLowerCase()] = value;
      });

      final result = LessonMp4ProbeResult(
        url: uri.toString(),
        statusCode: response.statusCode,
        headers: headers,
      );
      result.log();
      return result;
    } catch (error, stack) {
      debugPrint('[LessonMp4][probe] FAILED url=$uri error=$error');
      debugPrint('[LessonMp4][probe] stack=$stack');
      return LessonMp4ProbeResult(
        url: uri.toString(),
        statusCode: -1,
        headers: const {},
        probeError: error.toString(),
      );
    }
  }

  /// Map a raw player / HTTP failure to a stable code + Arabic message.
  ///
  /// `decode` is reserved for real codec/DRM failures only — not demux/open,
  /// network, or format-probe errors (those were previously mislabeled).
  static LessonMp4Failure classifyFailure(
    Object error, {
    StackTrace? stackTrace,
    LessonMp4ProbeResult? probe,
  }) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    debugPrint('[LessonMp4][failure] raw=$raw');
    if (stackTrace != null) {
      debugPrint('[LessonMp4][failure] stack=$stackTrace');
    }
    if (probe != null) {
      debugPrint(
        '[LessonMp4][failure] probe status=${probe.statusCode} '
        'contentType=${probe.contentType} acceptRanges=${probe.acceptRanges} '
        'length=${probe.contentLength}',
      );
    }

    if (probe != null && probe.statusCode > 0 && probe.statusCode >= 400) {
      return LessonMp4Failure(
        code: 'network',
        technical: 'HTTP ${probe.statusCode}',
        userMessage:
            'تعذّر تحميل الفيديو من الخادم (HTTP ${probe.statusCode}).',
      );
    }

    if (_isNetwork(lower)) {
      return LessonMp4Failure(
        code: 'network',
        technical: raw,
        userMessage:
            'تعذّر تحميل الفيديو. تحقّق من الاتصال ثم أعد المحاولة.',
      );
    }

    // Real DRM / encrypted sample entries — not present on Prime CDN MP4s.
    if (lower.contains('drm') ||
        lower.contains('widevine') ||
        lower.contains('fairplay') ||
        lower.contains('clearkey') ||
        lower.contains('license') && lower.contains('denied')) {
      return LessonMp4Failure(
        code: 'drm',
        technical: raw,
        userMessage:
            'هذا الفيديو محمي بنظام DRM ولا يمكن تشغيله بدون ترخيص.',
      );
    }

    // True decode / codec issues only.
    if (lower.contains('mediacodec') ||
        lower.contains('avc decoder') ||
        lower.contains('decoder failed') ||
        lower.contains('no decoder') ||
        (lower.contains('codec') && lower.contains('not supported'))) {
      return LessonMp4Failure(
        code: 'decode',
        technical: raw,
        userMessage: 'تعذّر فك تشفير الفيديو على هذا الجهاز.',
      );
    }

    // Extensionless / demux / open — previously misreported as "decrypt".
    if (lower.contains('demux') ||
        lower.contains('lavf') ||
        lower.contains('failed to open') ||
        lower.contains('could not open') ||
        lower.contains('unrecognized') ||
        lower.contains('no stream') ||
        lower.contains('invalid data')) {
      return LessonMp4Failure(
        code: 'open',
        technical: raw,
        userMessage:
            'تعذّر فتح ملف الفيديو. أعد المحاولة أو تحقق من الاتصال.',
      );
    }

    return LessonMp4Failure(
      code: 'unknown',
      technical: raw,
      userMessage:
          'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.',
    );
  }

  static bool _isNetwork(String lower) =>
      lower.contains('socket') ||
      lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('connection') ||
      lower.contains('network') ||
      lower.contains('host lookup') ||
      lower.contains('failed host') ||
      lower.contains('http status');
}

final class LessonMp4ProbeResult {
  const LessonMp4ProbeResult({
    required this.url,
    required this.statusCode,
    required this.headers,
    this.probeError,
  });

  final String url;
  final int statusCode;
  final Map<String, String> headers;
  final String? probeError;

  String? get contentType => headers['content-type'];
  String? get contentLength => headers['content-length'];
  String? get acceptRanges => headers['accept-ranges'];
  String? get accessControlAllowOrigin =>
      headers['access-control-allow-origin'];

  bool get looksLikeProgressiveMp4 {
    final type = (contentType ?? '').toLowerCase();
    return type.contains('video/mp4') || type.contains('application/mp4');
  }

  bool get hasByteRange =>
      (acceptRanges ?? '').toLowerCase().contains('bytes');

  void log() {
    debugPrint('[LessonMp4][probe] url=$url');
    debugPrint('[LessonMp4][probe] status=$statusCode');
    debugPrint('[LessonMp4][probe] content-type=$contentType');
    debugPrint('[LessonMp4][probe] content-length=$contentLength');
    debugPrint('[LessonMp4][probe] accept-ranges=$acceptRanges');
    debugPrint(
      '[LessonMp4][probe] access-control-allow-origin='
      '$accessControlAllowOrigin',
    );
    debugPrint('[LessonMp4][probe] kind=progressive-mp4 drm=none');
    if (probeError != null) {
      debugPrint('[LessonMp4][probe] error=$probeError');
    }
    headers.forEach((key, value) {
      debugPrint('[LessonMp4][probe][header] $key: $value');
    });
  }
}

final class LessonMp4Failure {
  const LessonMp4Failure({
    required this.code,
    required this.technical,
    required this.userMessage,
  });

  final String code;
  final String technical;
  final String userMessage;
}
