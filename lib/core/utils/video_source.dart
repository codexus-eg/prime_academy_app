import '../../data/courses/user_course.dart';

/// Mirrors web `extractYouTubeId` / `isValidYouTubeURL` / `isValidBunnyURL`
/// in `prime_academy-main/client/src/utils/string.ts`.
abstract final class VideoSource {
  static final _youtubeIdPattern = RegExp(
    r'(?:youtube\.com/(?:[^/]+/.+/|(?:v|embed)/|.*[?&]v=)|youtu\.be/)([^"&?/ ]{11})',
    caseSensitive: false,
  );

  static final _bunnyUuidPattern = RegExp(
    r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
    caseSensitive: false,
  );

  static String? extractYouTubeId(String url) {
    if (url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host.contains('mediadelivery.net') || host.endsWith('.b-cdn.net')) {
        return null;
      }
    }

    final match = _youtubeIdPattern.firstMatch(url);
    if (match != null) return match.group(1);

    if (uri == null) return null;

    if (uri.host.toLowerCase() == 'youtu.be' ||
        uri.host.toLowerCase() == 'www.youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return (id != null && id.isNotEmpty) ? id : null;
    }
    if (uri.queryParameters['v']?.isNotEmpty == true) {
      return uri.queryParameters['v'];
    }
    final embedIndex = uri.pathSegments.indexOf('embed');
    if (embedIndex != -1 && embedIndex + 1 < uri.pathSegments.length) {
      final id = uri.pathSegments[embedIndex + 1];
      return id.isEmpty ? null : id;
    }
    return null;
  }

  static bool isValidYouTubeUrl(String url) => extractYouTubeId(url) != null;

  static bool isValidBunnyHlsUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.toLowerCase().endsWith('.b-cdn.net') &&
        url.toLowerCase().endsWith('.m3u8');
  }

  static String? extractBunnyVideoId(String url) =>
      _bunnyUuidPattern.firstMatch(url)?.group(1);

  static String withAutoplayDisabled(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final params = Map<String, String>.from(uri.queryParameters)
      ..['autoplay'] = 'false'
      ..['compactControls'] = 'true';
    return uri.replace(queryParameters: params).toString();
  }

  /// Strip parameters (`video/mp4; codecs=…` → `video/mp4`).
  static String normalizeMime(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return '';
    return mimeType.split(';').first.trim().toLowerCase();
  }

  /// Optional headers for non-lesson attachments (e.g. chat). Lesson MP4 from
  /// Prime CDN plays without custom headers — see [LessonMp4Diagnostics].
  static const Map<String, String> playbackHttpHeaders = {
    'Referer': 'https://primeacademy.education/',
    'Accept': '*/*',
  };

  /// Parse URL for YouTube / embed / general use. Lesson progressive MP4 must
  /// use [LessonMp4Diagnostics.playbackUrl] (no re-encode).
  static Uri networkUri(String url) {
    final parsed = Uri.parse(url.trim());
    if (!parsed.hasScheme || parsed.host.isEmpty) return parsed;

    final segments = parsed.pathSegments.map((segment) {
      try {
        return Uri.decodeComponent(segment);
      } catch (_) {
        return segment;
      }
    }).toList();

    return Uri(
      scheme: parsed.scheme,
      userInfo: parsed.userInfo.isEmpty ? null : parsed.userInfo,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      pathSegments: segments,
      queryParameters:
          parsed.queryParameters.isEmpty ? null : parsed.queryParameters,
      fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
    );
  }

  /// Same routing as web `VideoSection`:
  /// `mime === video/mp4` → MP4, else YouTube URL → YouTube, else Bunny embed.
  ///
  /// Progressive CDN lesson uploads are always stored as `video/mp4` with an
  /// extensionless R2 key (`uploads/lessons/<id>`). If mime is missing but the
  /// path is clearly a lesson upload key, treat as MP4 (API parity).
  static LessonVideoKind classify({
    required String? mimeType,
    required String? videoUrl,
  }) {
    if (videoUrl == null || videoUrl.isEmpty) return LessonVideoKind.none;
    final mime = normalizeMime(mimeType);

    // Web checks exact `video/mp4`. Normalize strips charset/codecs only.
    if (mime == 'video/mp4') return LessonVideoKind.mp4;

    // Lesson CDN keys without mime still play as progressive MP4 on web when
    // the dashboard uploaded an mp4 (mime is normally present).
    final uri = Uri.tryParse(videoUrl);
    if (mime.isEmpty &&
        uri != null &&
        uri.path.contains('/uploads/lessons/')) {
      return LessonVideoKind.mp4;
    }

    if (isValidYouTubeUrl(videoUrl)) return LessonVideoKind.youtube;
    return LessonVideoKind.embed;
  }

  /// Detect streaming container from URL for logging / future players.
  static String detectFormatLabel(String? videoUrl, String? mimeType) {
    final mime = normalizeMime(mimeType);
    if (mime == 'video/mp4') return 'progressive-mp4';
    if (mime == 'application/x-mpegurl' || mime == 'application/vnd.apple.mpegurl') {
      return 'hls';
    }
    if (mime == 'application/dash+xml') return 'dash';
    final url = (videoUrl ?? '').toLowerCase();
    if (url.contains('.m3u8')) return 'hls';
    if (url.contains('.mpd')) return 'dash';
    if (isValidYouTubeUrl(videoUrl ?? '')) return 'youtube';
    if (extractBunnyVideoId(videoUrl ?? '') != null) return 'bunny-embed';
    if (url.contains('.mp4')) return 'progressive-mp4';
    return 'unknown';
  }
}
