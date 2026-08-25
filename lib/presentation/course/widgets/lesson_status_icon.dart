import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'lesson_check_mark.dart';

class LessonStatusIcon extends StatelessWidget {
  const LessonStatusIcon({
    super.key,
    this.progressPercent = 0,
    this.hasTrophy = false,
    this.showProgressRing = true,
    this.progressColor = AppColors.blue,
  });

  static const size = 25.0;
  static const viewBox = 36.0;
  static const outerRadius = 16.0;
  static const innerRadius = 14.0;
  static const outerStroke = 4.0;
  static const innerStroke = 3.0;
  static const centerDotSize = AppSpacing.md;
  static const checkSize = AppSpacing.base;

  final int progressPercent;
  final bool hasTrophy;
  final bool showProgressRing;
  final Color progressColor;

  double get _progress {
    if (!showProgressRing) return 0;
    return (progressPercent / 100).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LessonStatusIcon.size,
      height: LessonStatusIcon.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(LessonStatusIcon.size, LessonStatusIcon.size),
            painter: _LessonRingPainter(
              progress: _progress,
              outerStrokeColor: AppColors.accent,
              progressColor: progressColor,
            ),
          ),
          Container(
            width: LessonStatusIcon.centerDotSize,
            height: LessonStatusIcon.centerDotSize,
            decoration: BoxDecoration(
              color: progressColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: hasTrophy
                ? const LessonCheckMark(
                    color: AppColors.lessonStatusRing,
                    size: LessonStatusIcon.checkSize,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _LessonRingPainter extends CustomPainter {
  const _LessonRingPainter({
    required this.progress,
    required this.outerStrokeColor,
    required this.progressColor,
  });

  final double progress;
  final Color outerStrokeColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / LessonStatusIcon.viewBox;
    final center = Offset(
      LessonStatusIcon.viewBox / 2 * scale,
      LessonStatusIcon.viewBox / 2 * scale,
    );
    final innerCenter = Offset(18 * scale, 18.5 * scale);

    final outerPaint = Paint()
      ..color = outerStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = LessonStatusIcon.outerStroke * scale;

    canvas.drawCircle(
      center,
      LessonStatusIcon.outerRadius * scale,
      outerPaint,
    );

    if (progress <= 0) return;

    final innerPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = LessonStatusIcon.innerStroke * scale
      ..strokeCap = StrokeCap.round;

    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(
        center: innerCenter,
        radius: LessonStatusIcon.innerRadius * scale,
      ),
      -math.pi / 2,
      sweep,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LessonRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
