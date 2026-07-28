import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CssLessonActionGradientPainter extends CustomPainter {
  CssLessonActionGradientPainter({
    required this.size,
    required this.accent,
    this.background = AppColors.contentBtnBg,
  });

  final Size size;
  final Color accent;
  final Color background;

  static const double ellipseWidthPercent = 81.78;
  static const double ellipseHeightPercent = 136.62;

  static const double centerXPercent = -11.07;
  static const double centerYPercent = 120.87;

  static Color samplePixel(
    double px,
    double py,
    double width,
    double height,
    Color accent,
    Color background,
  ) {
    if (width <= 0 || height <= 0) {
      return background;
    }

    final rx = width * (ellipseWidthPercent / 100);
    final ry = height * (ellipseHeightPercent / 100);
    final cx = width * (centerXPercent / 100);
    final cy = height * (centerYPercent / 100);

    if (rx <= 0 || ry <= 0) {
      return background;
    }

    final dx = (px - cx) / rx;
    final dy = (py - cy) / ry;
    final t = math.sqrt(dx * dx + dy * dy);

    if (t >= 1) {
      return background;
    }

    return Color.lerp(accent, background, t)!;
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
        paint.color = samplePixel(
          x + 0.5,
          y + 0.5,
          width,
          height,
          accent,
          background,
        );
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CssLessonActionGradientPainter oldDelegate) {
    return oldDelegate.size != size ||
        oldDelegate.accent != accent ||
        oldDelegate.background != background;
  }
}

class CssLessonActionGradientImageCache {
  static final _cache = <String, ui.Image>{};

  static Future<ui.Image?> imageFor(
    Size size,
    Color accent, {
    Color background = AppColors.contentBtnBg,
  }) async {
    if (size.width <= 0 || size.height <= 0) {
      return null;
    }

    final key =
        '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}_${accent.toARGB32()}_${background.toARGB32()}';
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    CssLessonActionGradientPainter(
      size: size,
      accent: accent,
      background: background,
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.ceil(),
      size.height.ceil(),
    );
    _cache[key] = image;
    return image;
  }
}

class CssLessonActionGradientLayer extends StatefulWidget {
  const CssLessonActionGradientLayer({
    super.key,
    required this.accent,
    this.background = AppColors.contentBtnBg,
  });

  final Color accent;
  final Color background;

  @override
  State<CssLessonActionGradientLayer> createState() =>
      _CssLessonActionGradientLayerState();
}

class _CssLessonActionGradientLayerState
    extends State<CssLessonActionGradientLayer> {
  ui.Image? _image;
  Size? _lastSize;
  Color? _lastBackground;

  @override
  void didUpdateWidget(covariant CssLessonActionGradientLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.background != widget.background ||
        oldWidget.accent != widget.accent) {
      _image = null;
      _lastSize = null;
      _lastBackground = null;
    }
  }

  void _syncImage(Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        (_lastSize == size &&
            _lastBackground == widget.background &&
            _image != null)) {
      return;
    }

    _lastSize = size;
    _lastBackground = widget.background;
    CssLessonActionGradientImageCache.imageFor(
      size,
      widget.accent,
      background: widget.background,
    ).then((image) {
      if (!mounted || _lastSize != size) {
        return;
      }
      setState(() => _image = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _syncImage(size);

        if (_image != null && _lastSize == size) {
          return RawImage(
            image: _image,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          );
        }

        return CustomPaint(
          painter: CssLessonActionGradientPainter(
            size: size,
            accent: widget.accent,
            background: widget.background,
          ),
          isComplex: true,
          willChange: false,
        );
      },
    );
  }
}
