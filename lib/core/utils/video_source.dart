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
    return uri.host.toLowerCase().endsWith('.b-cdn.net') && url.endsWith('.m3u8');
  }

  static String? extractBunnyVideoId(String url) =>
      _bunnyUuidPattern.firstMatch(url)?.group(1);

  static String withAutoplayDisabled(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final params = Map<String, String>.from(uri.queryParameters)
      ..['autoplay'] = 'false';
    return uri.replace(queryParameters: params).toString();
  }

  /// Same routing as web `VideoSection`:
  /// mp4 mime → MP4, else YouTube URL → YouTube, else Bunny embed.
  static LessonVideoKind classify({
    required String? mimeType,
    required String? videoUrl,
  }) {
    if (videoUrl == null || videoUrl.isEmpty) return LessonVideoKind.none;
    if (mimeType?.toLowerCase() == 'video/mp4') return LessonVideoKind.mp4;
    if (isValidYouTubeUrl(videoUrl)) return LessonVideoKind.youtube;
    return LessonVideoKind.embed;
  }
}
