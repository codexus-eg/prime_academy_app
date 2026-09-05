import 'dart:convert';

import '../../../core/utils/video_source.dart';

/// HTML5 progressive MP4 page that mirrors web Vidstack `MP4Player`:
/// `<video preload="none"><source type="video/mp4" src=…></video>`.
///
/// CDN lesson keys are extensionless (`uploads/lessons/<id>`). Browsers play
/// them because the MIME type is set on the `<source>` element.
abstract final class LessonMp4Html {
  static const bridgeName = 'Mp4Bridge';

  static String page({
    required String videoUrl,
    required String mimeType,
    String? posterUrl,
    required int resumeSeconds,
  }) {
    final src = _escapeAttr(VideoSource.networkUri(videoUrl).toString());
    final type = _escapeAttr(
      mimeType.isEmpty ? 'video/mp4' : VideoSource.normalizeMime(mimeType),
    );
    final poster = (posterUrl == null || posterUrl.isEmpty)
        ? ''
        : ' poster="${_escapeAttr(posterUrl)}"';
    // Match web MP4Player: preload="none" — poster first, bytes only after play.
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>
  html,body{margin:0;padding:0;width:100%;height:100%;background:#000;overflow:hidden}
  video{position:absolute;inset:0;width:100%;height:100%;object-fit:contain;background:#000}
</style>
</head>
<body>
<video id="v" playsinline webkit-playsinline preload="none"$poster controlsList="nodownload nofullscreen noremoteplayback">
  <source src="$src" type="$type">
</video>
<script>
(function () {
  var v = document.getElementById('v');
  var resumeAt = $resumeSeconds;
  var hasResumed = false;
  var loadStarted = false;

  function send(obj) {
    try { $bridgeName.postMessage(JSON.stringify(obj)); } catch (e) {}
  }

  function mediaErrorMessage() {
    if (!v.error) return 'unknown';
    switch (v.error.code) {
      case 1: return 'aborted';
      case 2: return 'network';
      case 3: return 'decode';
      case 4: return 'src_not_supported';
      default: return 'code_' + v.error.code;
    }
  }

  function ensureLoad() {
    if (loadStarted) return;
    loadStarted = true;
    try { v.load(); } catch (e) {}
  }

  window.__mp4 = {
    play: function () {
      ensureLoad();
      return v.play().then(function () {
        send({event:'play'});
      }).catch(function (e) {
        send({
          event:'error',
          code:'play_rejected',
          message: String(e && e.message ? e.message : e)
        });
      });
    },
    pause: function () { v.pause(); send({event:'pause'}); },
    seek: function (seconds) {
      ensureLoad();
      v.currentTime = Math.max(0, Number(seconds) || 0);
    },
    setMuted: function (muted) { v.muted = !!muted; v.volume = muted ? 0 : 1; },
    setRate: function (rate) { v.playbackRate = Number(rate) || 1; },
    getState: function () {
      send({
        event: 'state',
        seconds: v.currentTime || 0,
        duration: (isFinite(v.duration) ? v.duration : 0) || 0,
        paused: !!v.paused,
        ended: !!v.ended,
        readyState: v.readyState
      });
    }
  };

  v.addEventListener('loadstart', function () { send({event:'loadstart'}); });
  v.addEventListener('loadedmetadata', function () {
    send({
      event: 'ready',
      duration: (isFinite(v.duration) ? v.duration : 0) || 0,
      width: v.videoWidth || 0,
      height: v.videoHeight || 0
    });
    if (!hasResumed && resumeAt > 0) {
      hasResumed = true;
      var d = v.duration;
      var pos = resumeAt;
      if (isFinite(d) && d > 0 && pos >= d - 5) pos = Math.max(0, d - 5);
      if (pos > 0) v.currentTime = pos;
    }
  });
  v.addEventListener('canplay', function () { send({event:'canplay'}); });
  v.addEventListener('waiting', function () { send({event:'waiting'}); });
  v.addEventListener('playing', function () { send({event:'playing'}); });
  v.addEventListener('play', function () { send({event:'play'}); });
  v.addEventListener('pause', function () { send({event:'pause'}); });
  v.addEventListener('ended', function () { send({event:'ended'}); });
  v.addEventListener('timeupdate', function () {
    var d = (isFinite(v.duration) ? v.duration : 0) || 0;
    send({event:'timeupdate', seconds: v.currentTime || 0, duration: d});
  });
  v.addEventListener('seeked', function () {
    var d = (isFinite(v.duration) ? v.duration : 0) || 0;
    send({event:'seeked', seconds: v.currentTime || 0, duration: d});
  });
  v.addEventListener('error', function () {
    send({event:'error', code: mediaErrorMessage(), message: mediaErrorMessage()});
  });

  // Shell is ready — Flutter can show the poster immediately (preload=none).
  send({event:'shell_ready'});
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

  static String userMessageForError(String? code) {
    switch (code) {
      case 'network':
        return 'تعذّر تحميل الفيديو. تحقّق من الاتصال ثم أعد المحاولة.';
      case 'decode':
        return 'تعذّر فك تشفير الفيديو على هذا الجهاز.';
      case 'src_not_supported':
        return 'صيغة الفيديو غير مدعومة أو الرابط غير صالح.';
      case 'aborted':
        return 'تم إيقاف تحميل الفيديو. أعد المحاولة.';
      case 'play_rejected':
        return 'تعذّر بدء التشغيل. اضغط التشغيل مرة أخرى.';
      default:
        return 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.';
    }
  }

  static String _escapeAttr(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
