import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Tears down lesson platform views (WebView / media_kit / YouTube) before
/// route replacement.
///
/// Active-session notification → Ranking fails on device when a lesson video
/// surface is still attached: Flutter paints HomeShell tabs, but a leftover
/// native view covers the ranking body (near-black void). Direct Ranking and
/// cold-start notifications do not hit this because no live player exists.
class LessonSurfaceGate extends ChangeNotifier {
  LessonSurfaceGate._();

  static final LessonSurfaceGate instance = LessonSurfaceGate._();

  var _suppressed = false;
  final _releasers = <Future<void> Function()>{};

  bool get suppressed => _suppressed;

  void register(Future<void> Function() release) {
    _releasers.add(release);
  }

  void unregister(Future<void> Function() release) {
    _releasers.remove(release);
  }

  /// Pause/detach every registered player, wait for frames so native views
  /// leave the hierarchy, then allow navigation.
  Future<void> suppressForNavigation() async {
    if (kDebugMode) {
      debugPrint(
        '[LessonSurface] suppressForNavigation '
        '(${_releasers.length} releaser(s))',
      );
    }
    _suppressed = true;
    notifyListeners();

    final tasks = _releasers.map((release) async {
      try {
        await release();
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[LessonSurface] releaser failed: $error');
        }
      }
    }).toList(growable: false);

    await Future.wait(tasks);

    final binding = WidgetsBinding.instance;
    for (var i = 0; i < 2; i++) {
      binding.scheduleFrame();
      try {
        await binding.endOfFrame
            .timeout(const Duration(milliseconds: 100));
      } on TimeoutException {
        // Idle binding (e.g. unit tests) — releasers already completed.
      }
    }

    if (kDebugMode) {
      debugPrint('[LessonSurface] surfaces released — safe to navigate');
    }
  }

  void resume() {
    if (!_suppressed) return;
    _suppressed = false;
    if (kDebugMode) {
      debugPrint('[LessonSurface] resume');
    }
    notifyListeners();
  }
}
