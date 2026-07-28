import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CssBgGradientPainter extends CustomPainter {
  CssBgGradientPainter({required this.size});

  final Size size;

  static const double ellipticalExtent = _sqrt2 * 1.2;

  static const double _sqrt2 = 1.4142135623730951;

  static Color samplePixel(double x, double y, double width, double height) {
    if (width <= 0 || height <= 0) {
      return AppColors.mainBg3;
    }

    final norm = math.sqrt(
      math.pow((x - width) / width, 2) + math.pow(y / height, 2),
    );
    final stop = (norm / ellipticalExtent).clamp(0.0, 1.0);
    final gradientColor = Color.lerp(
      AppColors.accent,
      AppColors.secondary,
      stop,
    )!;
    return Color.alphaBlend(gradientColor, AppColors.mainBg3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    if (width <= 0 || height <= 0) {
      return;
    }

    final paint = Paint();
    final w = width.ceil();
    final h = height.ceil();

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        paint.color = samplePixel(x + 0.5, y + 0.5, width, height);
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CssBgGradientPainter oldDelegate) {
    return oldDelegate.size != size;
  }
}

class CssBgGradientImageCache {
  static final _cache = <String, ui.Image>{};

  static Future<ui.Image?> imageFor(Size size) async {
    if (size.width <= 0 || size.height <= 0) {
      return null;
    }

    final key =
        '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}';
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    CssBgGradientPainter(size: size).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.ceil(),
      size.height.ceil(),
    );
    _cache[key] = image;
    return image;
  }
}
