import 'package:flutter_test/flutter_test.dart';

import 'package:prime_flutter/core/utils/bunny_hls_manifest.dart';

void main() {
  test('parseMasterPlaylist extracts all RESOLUTION heights', () {
    const body = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=600000,RESOLUTION=352x240
352x240/video.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
640x360/video.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=842x480
842x480/video.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
1280x720/video.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=5000000,RESOLUTION=1920x1080
1920x1080/video.m3u8
''';

    final variants = BunnyHlsManifest.parseMasterPlaylist(
      body,
      'https://vz-example.b-cdn.net/video-id/playlist.m3u8',
    );

    expect(
      variants.map((v) => v.label).toList(),
      ['240p', '360p', '480p', '720p', '1080p'],
    );
    expect(
      variants.last.uri,
      'https://vz-example.b-cdn.net/video-id/1920x1080/video.m3u8',
    );
  });

  test('parseMasterPlaylist skips duplicates and sorts by height', () {
    const body = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
1280x720/video.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=600000,RESOLUTION=352x240
352x240/video.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=610000,RESOLUTION=400x240
400x240/video.m3u8
''';

    final variants = BunnyHlsManifest.parseMasterPlaylist(
      body,
      'https://cdn.example/playlist.m3u8',
    );

    expect(variants.map((v) => v.label).toList(), ['240p', '720p']);
  });
}
