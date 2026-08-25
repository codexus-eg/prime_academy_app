import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/auth/auth_session.dart';
import '../../data/courses/courses_api.dart';

/// Mirrors web `useVideoProgress`: sync every 10s while playing, on pause,
/// on seek, and when the player is disposed.
class LessonPlaybackTracker {
  LessonPlaybackTracker({
    required this.lessonId,
    this.onWatched,
  });

  final int? lessonId;
  final VoidCallback? onWatched;

  static const syncInterval = Duration(seconds: 10);

  var _canTrack = false;
  var _lastSyncedSeconds = -1;
  var _seconds = 0;
  var _duration = 0;
  var _playing = false;
  Timer? _timer;

  bool get canTrack => _canTrack;

  Future<void> resolve() async {
    if (lessonId == null) return;
    final user = await AuthSession.load();
    _canTrack = user?.role == 1;
  }

  void update({required int seconds, required int duration}) {
    _seconds = seconds;
    _duration = duration;
  }

  void onPlay() {
    _playing = true;
    _timer ??= Timer.periodic(syncInterval, (_) {
      if (_playing) unawaited(sync());
    });
  }

  void onPause() {
    _playing = false;
    _timer?.cancel();
    _timer = null;
    unawaited(sync());
  }

  Future<void> sync() async {
    if (!_canTrack) return;
    final id = lessonId;
    if (id == null || _duration <= 0) return;

    final seconds = _seconds;
    if (seconds == _lastSyncedSeconds) return;
    _lastSyncedSeconds = seconds;

    try {
      final watched = await CoursesApi.saveVideoProgress(
        lessonId: id,
        progressSeconds: seconds,
      );
      if (watched) onWatched?.call();
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(sync());
  }
}

class StallWatch {
  StallWatch({
    required this.thresholdSeconds,
    required this.onStall,
  });

  final int thresholdSeconds;
  final VoidCallback onStall;

  Timer? _timer;
  var _lastTime = 0.0;
  var _stalledFor = 0;
  var _playing = false;

  void setPlaying(bool playing) => _playing = playing;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_playing) {
        _stalledFor = 0;
        return;
      }
      if ((_lastTime - _current).abs() < 0.05) {
        _stalledFor += 1;
        if (_stalledFor >= thresholdSeconds) {
          _stalledFor = 0;
          onStall();
        }
      } else {
        _stalledFor = 0;
      }
      _lastTime = _current;
    });
  }

  double _current = 0;

  void reportTime(double seconds) => _current = seconds;

  void reset() {
    _stalledFor = 0;
    _lastTime = _current;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
