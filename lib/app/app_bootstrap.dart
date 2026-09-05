import 'package:flutter/widgets.dart';

/// Coordinates cold-start splash handoff from the native launch screen to
/// [SplashPage]'s first painted frame.
abstract final class AppBootstrap {
  static var _firstFrameDeferred = false;

  static void deferFirstFrameUntilSplashReady() {
    WidgetsBinding.instance.deferFirstFrame();
    _firstFrameDeferred = true;
  }

  static void releaseFirstFrameIfDeferred() {
    if (!_firstFrameDeferred) return;
    _firstFrameDeferred = false;
    WidgetsBinding.instance.allowFirstFrame();
  }
}
