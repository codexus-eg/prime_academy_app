import 'package:flutter/material.dart';

class LucideChevronLeftIcon extends StatelessWidget {
  const LucideChevronLeftIcon({
    super.key,
    required this.color,
    this.size = 16,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChevronLeftPainter(color: color),
      ),
    );
  }
}

class _ChevronLeftPainter extends CustomPainter {
  _ChevronLeftPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.625, size.height * 0.75)
      ..lineTo(size.width * 0.375, size.height * 0.5)
      ..lineTo(size.width * 0.625, size.height * 0.25);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronLeftPainter oldDelegate) =>
      oldDelegate.color != color;
}
