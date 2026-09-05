import 'package:http/http.dart' as http;

/// Resolves Bunny Stream HLS master playlists and variant qualities from an
/// embed URL or a direct `.m3u8` URL — no hardcoded resolution list.
abstract final class BunnyHlsManifest {
  static const referer = 'https://iframe.mediadelivery.net/';

  static final _playlistUrlPattern = RegExp(
    r'https://[^"\s<>]+playlist\.m3u8[^"\s<>]*',
    caseSensitive: false,
  );

  static final _streamInfPattern = RegExp(
    r'#EXT-X-STREAM-INF:([^\r\n]+)\r?\n([^\r\n#]+)',
  );

  static final _resolutionPattern = RegExp(
    r'RESOLUTION=(\d+)x(\d+)',
    caseSensitive: false,
  );

  /// Returns master playlist URL + discovered labels (e.g. `240p`), or null.
  static Future<BunnyHlsResolved?> resolve(String videoUrl) async {
    final trimmed = videoUrl.trim();
    if (trimmed.isEmpty) return null;

    final playlistUrl = await _resolvePlaylistUrl(trimmed);
    if (playlistUrl == null) return null;

    final variants = await _parseVariants(playlistUrl);
    if (variants.isEmpty) {
      // Master URL is still usable for Auto even if parse failed.
      return BunnyHlsResolved(
        playlistUrl: playlistUrl,
        variants: const [],
      );
    }
    return BunnyHlsResolved(playlistUrl: playlistUrl, variants: variants);
  }

  static Future<String?> _resolvePlaylistUrl(String videoUrl) async {
    final lower = videoUrl.toLowerCase();
    if (lower.contains('.m3u8')) return videoUrl;

    // Embed / play pages include the CDN playlist URL in HTML.
    try {
      final response = await http
          .get(Uri.parse(videoUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return null;
      }
      final match = _playlistUrlPattern.firstMatch(response.body);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }

  static Future<List<BunnyHlsVariant>> _parseVariants(String playlistUrl) async {
    try {
      final response = await http
          .get(
            Uri.parse(playlistUrl),
            headers: const {'Referer': referer},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return const [];
      }
      return parseMasterPlaylist(response.body, playlistUrl);
    } catch (_) {
      return const [];
    }
  }

  /// Pure parser for unit tests.
  static List<BunnyHlsVariant> parseMasterPlaylist(
    String body,
    String playlistUrl,
  ) {
    final base = Uri.parse(playlistUrl);
    final seen = <String>{};
    final variants = <BunnyHlsVariant>[];

    for (final match in _streamInfPattern.allMatches(body)) {
      final attrs = match.group(1) ?? '';
      final relative = (match.group(2) ?? '').trim();
      if (relative.isEmpty) continue;

      final res = _resolutionPattern.firstMatch(attrs);
      final height = int.tryParse(res?.group(2) ?? '') ?? 0;
      if (height <= 0) continue;

      final label = '${height}p';
      if (!seen.add(label)) continue;

      final uri = base.resolve(relative).toString();
      variants.add(BunnyHlsVariant(label: label, uri: uri, height: height));
    }

    variants.sort((a, b) => a.height.compareTo(b.height));
    return variants;
  }

  static Map<String, String> get playbackHeaders => const {
        'Referer': referer,
      };
}

class BunnyHlsResolved {
  const BunnyHlsResolved({
    required this.playlistUrl,
    required this.variants,
  });

  final String playlistUrl;
  final List<BunnyHlsVariant> variants;

  /// Labels for the quality menu (Auto is added by the UI).
  List<String> get qualityLabels => [
        for (final v in variants) v.label,
      ];
}

class BunnyHlsVariant {
  const BunnyHlsVariant({
    required this.label,
    required this.uri,
    required this.height,
  });

  final String label;
  final String uri;
  final int height;
}
