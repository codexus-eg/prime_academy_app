import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Alarm used only for [SESSION_LIVE] — same asset as web `bell-alarm.mp3`
/// and a stronger version of the web vibration pattern.
abstract final class LiveSessionAlarm {
  static final AudioPlayer _player = AudioPlayer();
  static var _ready = false;

  /// Same relative pattern as web `[200, 150, 200, 150, 200]`, expressed for
  /// Android/iOS as `[delay, vibrate, pause, vibrate, ...]`, with stronger
  /// pulse lengths for a more forceful alert.
  static const vibrationPattern = <int>[
    0,
    400,
    120,
    400,
    120,
    450,
    100,
    500,
  ];

  /// Max amplitude on every vibrate slot (0 = pause slot).
  static const vibrationIntensities = <int>[
    0,
    255,
    0,
    255,
    0,
    255,
    0,
    255,
  ];

  static const assetPath = 'web/sounds/bell-alarm.mp3';

  static Future<void> play() async {
    await Future.wait([
      _vibrate(),
      _playSound(),
    ]);
  }

  static Future<void> _playSound() async {
    try {
      if (!_ready) {
        await _player.setVolume(0.9);
        await _player.setReleaseMode(ReleaseMode.release);
        _ready = true;
      }
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (error) {
      debugPrint('[LiveSessionAlarm] sound failed: $error');
    }
  }

  static Future<void> _vibrate() async {
    if (kIsWeb) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;

      final supportsCustom = await Vibration.hasCustomVibrationsSupport();
      if (supportsCustom) {
        final hasAmplitude = await Vibration.hasAmplitudeControl();
        await Vibration.vibrate(
          pattern: vibrationPattern,
          intensities: hasAmplitude ? vibrationIntensities : const [],
        );
        return;
      }

      await Vibration.vibrate(duration: 800, amplitude: 255);
    } catch (error) {
      debugPrint('[LiveSessionAlarm] vibration failed: $error');
    }
  }
}
