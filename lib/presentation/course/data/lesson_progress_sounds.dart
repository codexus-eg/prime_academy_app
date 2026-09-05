import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sounds for the lesson aside progress circle (`WobblyCircle`).
abstract final class LessonProgressSounds {
  static const _notification = 'web/sounds/notification.mp3';
  static const _levelUp = 'web/sounds/level-up.mp3';

  static final AudioPlayer _player = AudioPlayer();
  static var _volumeReady = false;
  static var _lastTickScore = -1;

  static Future<void> _ensureVolume() async {
    if (_volumeReady) return;
    await _player.setVolume(0.75);
    _volumeReady = true;
  }

  /// Played once when the circle percentage starts counting up.
  static Future<void> playIncreaseStart() async {
    try {
      await HapticFeedback.lightImpact();
      await _ensureVolume();
      await _player.stop();
      await _player.play(AssetSource(_notification));
    } catch (_) {}
  }

  /// Soft click / selection haptic for each integer step of the counter.
  static Future<void> playCounterTick(int displayScore) async {
    if (displayScore == _lastTickScore) return;
    _lastTickScore = displayScore;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Played when the animated score reaches 100%.
  static Future<void> playComplete() async {
    try {
      await HapticFeedback.mediumImpact();
      await _ensureVolume();
      await _player.stop();
      await _player.play(AssetSource(_levelUp));
    } catch (_) {}
  }

  static void resetTickTracking() {
    _lastTickScore = -1;
  }
}
