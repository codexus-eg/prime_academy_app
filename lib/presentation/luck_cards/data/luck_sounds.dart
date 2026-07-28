import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'luck_assets.dart';

abstract final class LuckSounds {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _tickPlayer = AudioPlayer();
  static var _volumeReady = false;

  static Future<void> _ensureVolume() async {
    if (_volumeReady) return;
    await _player.setVolume(0.8);
    await _tickPlayer.setVolume(0.8);
    _volumeReady = true;
  }

  static Future<void> _play(String asset, {bool haptic = false, bool light = true}) async {
    if (haptic) {
      if (light) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    }
    await _ensureVolume();
    await _player.stop();
    await _player.play(AssetSource(asset));
  }

  static Future<void> playFlipCard() =>
      _play(LuckAssets.flipCardSound);

  static Future<void> playCorrect() =>
      _play(LuckAssets.correctSound, haptic: true);

  static Future<void> playIncorrect() =>
      _play(LuckAssets.incorrectSound, haptic: true, light: false);

  static Future<void> startTimeTick() async {
    await _ensureVolume();
    await _tickPlayer.setReleaseMode(ReleaseMode.loop);
    await _tickPlayer.stop();
    await _tickPlayer.play(AssetSource(LuckAssets.timeTickSound));
  }

  static Future<void> stopTimeTick() async {
    await _tickPlayer.stop();
  }
}
