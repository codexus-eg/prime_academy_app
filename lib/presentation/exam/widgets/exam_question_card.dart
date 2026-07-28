import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';
import 'exam_progress_bar.dart';
import 'exam_question_icons.dart';

class ExamQuestionCard extends StatelessWidget {
  const ExamQuestionCard({
    super.key,
    required this.prompt,
    required this.progressPercentage,
    this.visible = true,
    this.isRtl = false,
  });

  final String prompt;
  final int progressPercentage;
  final bool visible;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final textDirection = QuizHtmlText.detectTextDirection(prompt);
    final rtl = isRtl || textDirection == TextDirection.rtl;

    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        child: AnimatedScale(
          scale: visible ? 1 : 0.95,
          duration: const Duration(milliseconds: 280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;

              final cardWidth = maxWidth * 0.95;
              final minWidth =
                  maxWidth >= 640 ? maxWidth * 0.6 : maxWidth * 0.95;

              return Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: cardWidth.clamp(minWidth, cardWidth),

                  height: 160,
                  margin: const EdgeInsets.only(top: 32),
                  decoration: BoxDecoration(
                    color: AppColors.examPanelBg,
                    borderRadius:
                        BorderRadius.circular(AppRadius.tailwind2xl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14007BFF),
                        blurRadius: 60,
                      ),
                      BoxShadow(
                        color: Color(0xCC000000),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Color(0x0D007BFF),
                        blurRadius: 30,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppRadius.tailwind2xl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 1.2,
                                  colors: [
                                    AppColors.examAccentBlue
                                        .withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 120,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.06),
                                    Colors.white.withValues(alpha: 0.02),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.4, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      4,
                                      4,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const ExamQuestionHexBadge(),
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                            Text(
                                              rtl ? 'سؤال' : 'Question',
                                              style: AppTypography.bodySm
                                                  .copyWith(
                                                color: const Color(0xFF5AB4FF),
                                                fontWeight: AppFonts.bold,
                                                letterSpacing: rtl ? 0 : 1.6,
                                                shadows: const [
                                                  Shadow(
                                                    color: Color(0xB3007BFF),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xl,
                                            ),
                                            child: ExamProgressBar(
                                              progressPercentage:
                                                  progressPercentage,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 80,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.xl,
                                      0,
                                      AppSpacing.xl,
                                      AppSpacing.md,
                                    ),
                                    child: QuizHtmlText(
                                      html: prompt,
                                      textAlign: TextAlign.center,
                                      baseStyle: AppTypography.size20.copyWith(
                                        color: AppColors.onDark,
                                        fontWeight: AppFonts.regular,
                                        height: 1.45,
                                        shadows: const [
                                          Shadow(
                                            color: Color(0xCC000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                          Shadow(
                                            color: Color(0x26007BFF),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Positioned(
                            bottom: 12,
                            left: 12,
                            child: _CornerAccent(
                              kind: _CornerAccentKind.bottomLeft,
                              color: Color(0x4D14B8A6),
                            ),
                          ),
                          const Positioned(
                            bottom: 12,
                            right: 12,
                            child: _CornerAccent(
                              kind: _CornerAccentKind.bottomRight,
                              color: Color(0x4DF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _CornerAccentKind { bottomLeft, bottomRight }

class _CornerAccent extends StatelessWidget {
  const _CornerAccent({
    required this.kind,
    required this.color,
  });

  final _CornerAccentKind kind;
  final Color color;

  static const _radius = 4.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: CustomPaint(
        painter: _CornerAccentPainter(
          kind: kind,
          color: color,
          radius: _radius,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _CornerAccentPainter extends CustomPainter {
  const _CornerAccentPainter({
    required this.kind,
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final _CornerAccentKind kind;
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final inset = strokeWidth / 2;
    final path = Path();
    if (kind == _CornerAccentKind.bottomLeft) {
      path.moveTo(inset, inset);
      path.lineTo(inset, size.height - radius);
      path.arcToPoint(
        Offset(radius, size.height - inset),
        radius: Radius.circular(radius - inset),
        clockwise: false,
      );
      path.lineTo(size.width - inset, size.height - inset);
    } else {
      path.moveTo(inset, size.height - inset);
      path.lineTo(size.width - radius, size.height - inset);
      path.arcToPoint(
        Offset(size.width - inset, size.height - radius),
        radius: Radius.circular(radius - inset),
        clockwise: false,
      );
      path.lineTo(size.width - inset, inset);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerAccentPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
