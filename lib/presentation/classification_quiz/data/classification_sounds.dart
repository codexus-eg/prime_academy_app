import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../data/classification_assets.dart';

abstract final class ClassificationSounds {
  static final AudioPlayer _player = AudioPlayer();
  static var _volumeReady = false;

  static Future<void> _ensureVolume() async {
    if (_volumeReady) return;
    await _player.setVolume(0.8);
    _volumeReady = true;
  }

  static Future<void> _play(String asset, {required bool lightHaptic}) async {
    if (lightHaptic) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
    await _ensureVolume();
    await _player.stop();
    await _player.play(AssetSource(asset));
  }

  static Future<void> playCorrect() =>
      _play(ClassificationAssets.correctSound, lightHaptic: true);

  static Future<void> playIncorrect() =>
      _play(ClassificationAssets.incorrectSound, lightHaptic: false);

  static Future<void> playLevelUp() =>
      _play(ClassificationAssets.levelUpSound, lightHaptic: true);
}
