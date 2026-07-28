import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get isBrowserFullscreen => web.document.fullscreenElement != null;

Future<void> enterBrowserFullscreen() async {
  final doc = web.document.documentElement;
  if (doc == null) return;
  try {
    await doc.requestFullscreen().toDart;
  } catch (_) {}
}

Future<void> exitBrowserFullscreen() async {
  if (web.document.fullscreenElement == null) return;
  try {
    await web.document.exitFullscreen().toDart;
  } catch (_) {}
}

Future<void> requestWebElementFullscreen(Object? element) async {
  if (element case web.Element el) {
    try {
      await el.requestFullscreen().toDart;
      return;
    } catch (_) {}
  }
  await enterBrowserFullscreen();
}

bool isElementFullscreen(web.Element element) =>
    web.document.fullscreenElement == element || isBrowserFullscreen;
