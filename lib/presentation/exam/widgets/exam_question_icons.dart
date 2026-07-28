import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class ExamQuestionMarkIcon extends StatelessWidget {
  const ExamQuestionMarkIcon({super.key, this.size = 20});

  final double size;

  static const _glowColor = Color(0xE60096FF);

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#000000" d="M11.07 12.85c.77-1.39 2.25-2.21 3.11-3.44.91-1.29.4-3.7-2.18-3.7-1.69 0-2.52 1.28-2.87 2.34L6.54 6.96C7.25 4.83 9.18 3 11.99 3c2.35 0 3.96 1.07 4.78 2.41.7 1.15 1.11 3.3.03 4.9-1.2 1.77-2.35 2.31-2.97 3.45-.25.46-.35.76-.35 2.24h-2.89c-.01-.78-.13-2.05.48-3.15M14 20c0 1.1-.9 2-2 2s-2-.9-2-2 .9-2 2-2 2 .9 2 2"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final glow = SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(_glowColor, BlendMode.srcIn),
    );
    final icon = SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(AppColors.onDark, BlendMode.srcIn),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: glow,
          ),
          icon,
        ],
      ),
    );
  }
}

class ExamQuestionHexBadge extends StatelessWidget {
  const ExamQuestionHexBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(38, 38),
            painter: _HexBadgePainter(),
          ),
          const ExamQuestionMarkIcon(size: 20),
        ],
      ),
    );
  }
}

class _HexBadgePainter extends CustomPainter {
  static const _fill = Color.fromRGBO(0, 60, 160, 0.55);
  static const _stroke = Color(0xFF007BFF);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 38;
    final sy = size.height / 38;

    final path = Path()
      ..moveTo(19 * sx, 2 * sy)
      ..lineTo(35 * sx, 10.5 * sy)
      ..lineTo(35 * sx, 27.5 * sy)
      ..lineTo(19 * sx, 36 * sy)
      ..lineTo(3 * sx, 27.5 * sy)
      ..lineTo(3 * sx, 10.5 * sy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = _stroke.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sx
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = _fill
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = _stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sx,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
