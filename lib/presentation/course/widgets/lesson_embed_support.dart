import 'dart:convert';

import '../../../core/utils/video_source.dart';

abstract final class LessonEmbedSupport {
  static const playerJsUrl =
      'https://assets.mediadelivery.net/playerjs/playerjs-latest.min.js';

  static const allow =
      'accelerometer; gyroscope; encrypted-media; picture-in-picture';

  static String wrapperHtml({
    required String videoUrl,
    required int resumeSeconds,
  }) {
    final src = VideoSource.withAutoplayDisabled(videoUrl)
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;');
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
  html,body{margin:0;padding:0;width:100%;height:100%;background:#000;overflow:hidden}
  iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
</style>
</head>
<body>
<iframe id="p" src="$src" allowfullscreen allow="$allow"></iframe>
<script src="$playerJsUrl"></script>
<script>
(function () {
  var resumeAt = $resumeSeconds;
  function send(obj) {
    try { BunnyBridge.postMessage(JSON.stringify(obj)); } catch (e) {}
  }
  function init() {
    if (!window.playerjs) { send({event:'error'}); return; }
    var player = new playerjs.Player(document.getElementById('p'));
    window.__player = player;
    player.on('ready', function () {
      send({event:'ready'});
      player.getDuration(function (duration) {
        var pos = resumeAt;
        if (duration > 0 && pos >= duration - 5) pos = Math.max(0, duration - 5);
        if (pos > 0) player.setCurrentTime(pos);
      });
      player.on('timeupdate', function (data) {
        send({event:'timeupdate', seconds: data.seconds, duration: data.duration});
      });
      player.on('play', function () { send({event:'play'}); });
      player.on('pause', function () { send({event:'pause'}); });
      player.on('ended', function () { send({event:'ended'}); });
      player.on('error', function () { send({event:'error'}); });
      player.on('seeked', function () {
        player.getCurrentTime(function (time) {
          player.getDuration(function (duration) {
            send({event:'seeked', seconds: time, duration: duration});
          });
        });
      });
    });
  }
  if (window.playerjs) init();
  else {
    var s = document.querySelector('script[src*="playerjs"]');
    if (s) s.onload = init;
    else init();
  }
})();
</script>
</body>
</html>
''';
  }

  static Map<String, dynamic>? parseMessage(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}
