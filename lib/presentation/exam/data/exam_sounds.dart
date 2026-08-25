import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'exam_assets.dart';

abstract final class ExamSounds {
  static final AudioPlayer _player = AudioPlayer();
  static var _enabled = false;
  static var _volumeReady = false;

  static void enable() => _enabled = true;

  static Future<void> _ensureVolume() async {
    if (_volumeReady) return;
    await _player.setVolume(0.8);
    _volumeReady = true;
  }

  static Future<void> playCorrect() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
    await _ensureVolume();
    await _player.stop();
    await _player.play(AssetSource(ExamAssets.correctSound));
  }

  static Future<void> playIncorrect() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
    await _ensureVolume();
    await _player.stop();
    await _player.play(AssetSource(ExamAssets.incorrectSound));
  }

  /// Stop any in-flight SFX so nothing bleeds into the next question.
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
