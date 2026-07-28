import 'package:flutter/material.dart';

import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_durations.dart';

class SplashBlobLayout {
  const SplashBlobLayout({
    required this.left,
    required this.top,
    this.reversed = false,
  });

  final double left;
  final double top;
  final bool reversed;
}

class SplashFrame {
  const SplashFrame({
    required this.primary,
    required this.secondary,
    required this.dotsArePurple,
  });

  final SplashBlobLayout primary;
  final SplashBlobLayout secondary;
  final List<bool> dotsArePurple;
}

abstract final class SplashFrames {
  static const designWidth = 401.72;
  static const designHeight = 873.68;
  static const blobSize = 384.0;

  static const duration = Duration(seconds: 3);
  static const frameInterval = AppDurations.splashFrame;

  static const frames = [
    SplashFrame(
      primary: SplashBlobLayout(left: -82.70, top: 218.42),
      secondary: SplashBlobLayout(left: 100.43, top: 271.28, reversed: true),
      dotsArePurple: [false, false, true],
    ),
    SplashFrame(
      primary: SplashBlobLayout(left: 74, top: 167),
      secondary: SplashBlobLayout(left: -108, top: 315, reversed: true),
      dotsArePurple: [false, true, false],
    ),
    SplashFrame(
      primary: SplashBlobLayout(left: 95, top: 275),
      secondary: SplashBlobLayout(left: -91, top: 124, reversed: true),
      dotsArePurple: [true, false, false],
    ),
    SplashFrame(
      primary: SplashBlobLayout(left: 9, top: 176),
      secondary: SplashBlobLayout(left: -73, top: 326, reversed: true),
      dotsArePurple: [false, false, true],
    ),
    SplashFrame(
      primary: SplashBlobLayout(left: 88, top: 166),
      secondary: SplashBlobLayout(left: -104, top: 263, reversed: true),
      dotsArePurple: [false, true, false],
    ),
    SplashFrame(
      primary: SplashBlobLayout(left: 101, top: 245),
      secondary: SplashBlobLayout(left: -192, top: 141, reversed: true),
      dotsArePurple: [true, false, false],
    ),
  ];

  static const orangeGradient = AppGradients.splashOrange;
  static const purpleGradient = AppGradients.splashPurple;

  static LinearGradient blobGradient({required bool reversed}) =>
      AppGradients.splashBlobDiagonal(reversed: reversed);

  static const glowBlurSigma = 72.0;
}
