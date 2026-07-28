import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../painting/css_bg_gradient_painter.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class BgGradientSurface extends StatelessWidget {
  const BgGradientSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.borderAuthForm,
    this.padding = const EdgeInsets.all(AppSpacing.courseCardTitlePadding),
    this.width,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: _BgGradientBeforeLayer()),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _BgGradientBeforeLayer extends StatefulWidget {
  const _BgGradientBeforeLayer();

  @override
  State<_BgGradientBeforeLayer> createState() => _BgGradientBeforeLayerState();
}

class _BgGradientBeforeLayerState extends State<_BgGradientBeforeLayer> {
  ui.Image? _image;
  Size? _lastSize;

  void _syncImage(Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        (_lastSize == size && _image != null)) {
      return;
    }

    _lastSize = size;
    CssBgGradientImageCache.imageFor(size).then((image) {
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
          painter: CssBgGradientPainter(size: size),
          isComplex: true,
          willChange: false,
        );
      },
    );
  }
}
