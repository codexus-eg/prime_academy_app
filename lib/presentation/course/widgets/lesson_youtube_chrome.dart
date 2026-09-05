import 'dart:convert';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Clips the YouTube iframe the same way Vidstack does on web: overflow hidden
/// + iframe height 1000% so logo, title, channel, related, and "Watch on YouTube"
/// are removed from the visible frame — not faded or disabled.
///
/// Must keep iframe `allow` permissions (especially `autoplay` + `encrypted-media`)
/// and a proper `referrerpolicy`; stripping them causes Error 153 / silent
/// play failures inside Flutter WebViews.
Future<void> hideYoutubeEmbedChrome(
  YoutubePlayerController controller, {
  required bool playing,
  required String thumbnailUrl,
}) async {
  final thumb = jsonEncode(thumbnailUrl);
  final display = playing ? 'none' : 'block';
  try {
    await controller.webViewController.runJavaScript('''
(function () {
  var ALLOW =
    'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen';

  function ensureReferrerMeta() {
    if (document.querySelector('meta[name="referrer"]')) return;
    var meta = document.createElement('meta');
    meta.name = 'referrer';
    meta.content = 'strict-origin-when-cross-origin';
    document.head.appendChild(meta);
  }

  function apply() {
    ensureReferrerMeta();

    var style = document.getElementById('yt-hide-chrome-style');
    if (!style) {
      style = document.createElement('style');
      style.id = 'yt-hide-chrome-style';
      style.textContent = [
        'html,body{width:100%!important;height:100%!important;margin:0!important;',
        'overflow:hidden!important;background:#000!important;}',
        '.embed-container{position:relative!important;width:100%!important;',
        'height:100%!important;overflow:hidden!important;background:#000!important;}',
        '.embed-container iframe,.embed-container object,.embed-container embed{',
        'position:absolute!important;left:0!important;top:50%!important;',
        'width:100%!important;height:1000%!important;max-height:none!important;',
        'transform:translateY(-50%)!important;pointer-events:none!important;',
        'border:none!important;}'
      ].join('');
      document.head.appendChild(style);
    }
    var html = document.documentElement;
    var body = document.body;
    if (html) {
      html.style.overflow = 'hidden';
      html.style.background = '#000';
    }
    if (body) {
      body.style.margin = '0';
      body.style.overflow = 'hidden';
      body.style.background = '#000';
    }
    var box = document.querySelector('.embed-container') || body;
    if (!box) return;
    box.style.overflow = 'hidden';
    var frames = box.getElementsByTagName('iframe');
    for (var i = 0; i < frames.length; i++) {
      var f = frames[i];
      f.style.setProperty('position', 'absolute', 'important');
      f.style.setProperty('left', '0', 'important');
      f.style.setProperty('top', '50%', 'important');
      f.style.setProperty('width', '100%', 'important');
      f.style.setProperty('height', '1000%', 'important');
      f.style.setProperty('max-height', 'none', 'important');
      f.style.setProperty('transform', 'translateY(-50%)', 'important');
      f.style.setProperty('pointer-events', 'none', 'important');
      f.style.border = 'none';
      // Keep playback permissions — never reduce allow to encrypted-media only.
      if (f.getAttribute('allow') !== ALLOW) {
        try { f.setAttribute('allow', ALLOW); } catch (e) {}
      }
      if (f.getAttribute('referrerpolicy') !== 'strict-origin-when-cross-origin') {
        try {
          f.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
        } catch (e) {}
      }
    }
    var blocker = document.getElementById('yt-ui-blocker');
    if (!blocker) {
      blocker = document.createElement('div');
      blocker.id = 'yt-ui-blocker';
      blocker.style.cssText =
        'position:absolute;inset:0;z-index:2147483647;background:#000 center/contain no-repeat;pointer-events:none;';
      box.appendChild(blocker);
    }
    blocker.style.display = '$display';
    blocker.style.backgroundImage = 'url(' + $thumb + ')';
  }
  if (!window.__ytHideChrome) {
    window.__ytHideChrome = true;
    // childList only — observing attributes re-triggers on every allow/style write.
    new MutationObserver(apply).observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  }
  apply();
})();
''');
  } catch (_) {}
}
