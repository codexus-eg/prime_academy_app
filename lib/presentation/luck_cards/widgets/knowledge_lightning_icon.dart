import 'package:flutter/material.dart';

import '../../../core/theme/app_quiz_palette.dart';

class KnowledgeLightningIcon extends StatelessWidget {
  const KnowledgeLightningIcon({
    super.key,
    this.size = 50,
    this.dim = false,
  });

  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KnowledgeLightningPainter(dim: dim),
      ),
    );
  }
}

class _KnowledgeLightningPainter extends CustomPainter {
  const _KnowledgeLightningPainter({required this.dim});

  final bool dim;

  Path _boltPath() {
    return Path()
      ..moveTo(13, 2)
      ..lineTo(4.5, 13.5)
      ..lineTo(11, 13.5)
      ..lineTo(10, 22)
      ..lineTo(19.5, 10.5)
      ..lineTo(13, 10.5)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);

    final path = _boltPath();

    if (dim) {
      canvas.drawPath(
        path,
        Paint()..color = AppQuizPalette.lightningDimFill,
      );
      return;
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = AppQuizPalette.lightningFillGradient.createShader(
          const Rect.fromLTWH(0, 0, 24, 24),
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = AppQuizPalette.lightningStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _KnowledgeLightningPainter oldDelegate) {
    return oldDelegate.dim != dim;
  }
}
