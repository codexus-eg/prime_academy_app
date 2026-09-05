import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/answers_direction.dart';
import '../../../core/widgets/quiz_html_text.dart';

/// Mirrors web `AnswerResultCard`: replaces the question title after submit
/// and lists the correct answer(s). Grows with content (no inner scroll).
class ExamAnswerResultCard extends StatelessWidget {
  const ExamAnswerResultCard({
    super.key,
    required this.isCorrect,
    required this.answers,
    this.showAsFillChars = false,
    this.answersDirection,
  });

  final bool isCorrect;
  final List<String> answers;
  final bool showAsFillChars;
  final AnswersDirection? answersDirection;

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? _ResultAccent.correct : _ResultAccent.incorrect;
    final sample = answers.isEmpty ? '' : answers.first;
    final configured = answersDirection?.textDirection;
    final rtl = configured == TextDirection.rtl ||
        (configured == null &&
            QuizHtmlText.detectTextDirection(sample) == TextDirection.rtl);
    final answerTextDirection =
        configured ?? QuizHtmlText.detectTextDirection(sample);
    final answerTextAlign = answersDirection?.textAlign ??
        (answerTextDirection == TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left);
    final badgeLabel = rtl
        ? (isCorrect ? 'إجابة صحيحة' : 'إجابة خاطئة')
        : (isCorrect ? 'Correct' : 'Incorrect');

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final cardWidth = maxWidth * 0.95;
          final minWidth = maxWidth >= 640 ? maxWidth * 0.6 : maxWidth * 0.95;
          final isMd = maxWidth >= 768;
          final minCardHeight = isMd ? 200.0 : 160.0;
          final answerFontSize = isMd ? 24.0 : 17.6;

          return Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: cardWidth.clamp(minWidth, cardWidth),
              constraints: BoxConstraints(minHeight: minCardHeight),
              margin: const EdgeInsets.only(top: 32),
              decoration: BoxDecoration(
                color: accent.cardBg,
                borderRadius: BorderRadius.circular(AppRadius.tailwind2xl),
                border: Border.all(color: accent.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: accent.ambientShadow,
                    blurRadius: 60,
                  ),
                  const BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accent.insetShadow,
                    blurRadius: 30,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tailwind2xl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                            child: Row(
                              children: [
                                _ResultHexBadge(accent: accent),
                                const SizedBox(width: 12),
                                Text(
                                  badgeLabel,
                                  style: AppTypography.bodySm.copyWith(
                                    color: accent.label,
                                    fontWeight: AppFonts.bold,
                                    letterSpacing: rtl ? 0 : 1.6,
                                    shadows: [
                                      Shadow(
                                        color: accent.labelGlow,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            child: Column(
                              children: [
                                Text(
                                  'الإجابة الصحيحة :',
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: AppTypography.custom(
                                    fontSize: answerFontSize,
                                    fontWeight: AppFonts.semibold,
                                    color: AppColors.onDark,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (showAsFillChars)
                                  _FillAnswerChars(
                                    answer: answers.isEmpty ? '' : answers.first,
                                    textDirection: answerTextDirection,
                                  )
                                else
                                  for (final answer in answers)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        answer,
                                        textAlign: answerTextAlign,
                                        textDirection: answerTextDirection,
                                        style: AppTypography.custom(
                                          fontSize: answerFontSize,
                                          fontWeight: AppFonts.regular,
                                          color: AppColors.onDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: _ResultCorner(
                          kind: _ResultCornerKind.bottomLeft,
                          color: accent.corner,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _ResultCorner(
                          kind: _ResultCornerKind.bottomRight,
                          color: accent.corner,
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
    );
  }
}

class _ResultAccent {
  const _ResultAccent({
    required this.cardBg,
    required this.border,
    required this.ambientShadow,
    required this.insetShadow,
    required this.hexFill,
    required this.hexStroke,
    required this.label,
    required this.labelGlow,
    required this.corner,
  });

  final Color cardBg;
  final Color border;
  final Color ambientShadow;
  final Color insetShadow;
  final Color hexFill;
  final Color hexStroke;
  final Color label;
  final Color labelGlow;
  final Color corner;

  static const correct = _ResultAccent(
    cardBg: Color(0xCC052E16),
    border: Color(0x4D4ADE80),
    ambientShadow: Color(0x144ADE80),
    insetShadow: Color(0x0D4ADE80),
    hexFill: Color(0x8C14532D),
    hexStroke: Color(0xFF4ADE80),
    label: Color(0xFF4ADE80),
    labelGlow: Color(0xB34ADE80),
    corner: Color(0x664ADE80),
  );

  static const incorrect = _ResultAccent(
    cardBg: Color(0xCC450A0A),
    border: Color(0x4DF87171),
    ambientShadow: Color(0x14F87171),
    insetShadow: Color(0x0DF87171),
    hexFill: Color(0x8C7F1D1D),
    hexStroke: Color(0xFFF87171),
    label: Color(0xFFF87171),
    labelGlow: Color(0xB3F87171),
    corner: Color(0x66F87171),
  );
}

class _ResultHexBadge extends StatelessWidget {
  const _ResultHexBadge({required this.accent});

  final _ResultAccent accent;

  @override
  Widget build(BuildContext context) {
    final correct = identical(accent, _ResultAccent.correct);
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(38, 38),
            painter: _ResultHexPainter(accent: accent),
          ),
          Icon(
            correct ? Icons.check_rounded : Icons.close_rounded,
            size: 20,
            color: Colors.white,
            shadows: [
              Shadow(color: accent.labelGlow, blurRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultHexPainter extends CustomPainter {
  const _ResultHexPainter({required this.accent});

  final _ResultAccent accent;

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

    canvas.drawPath(path, Paint()..color = accent.hexFill);
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.hexStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sx,
    );
  }

  @override
  bool shouldRepaint(covariant _ResultHexPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _FillAnswerChars extends StatelessWidget {
  const _FillAnswerChars({
    required this.answer,
    required this.textDirection,
  });

  final String answer;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final chars = answer.split('');
    return Directionality(
      textDirection: textDirection,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < chars.length; i++)
            if (chars[i] == ' ')
              const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.horizontal_rule_rounded,
                  color: Color(0x4DFFFFFF),
                  size: 28,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x6614532D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4ADE80), width: 2),
                ),
                child: Text(
                  chars[i],
                  textDirection: textDirection,
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

enum _ResultCornerKind { bottomLeft, bottomRight }

class _ResultCorner extends StatelessWidget {
  const _ResultCorner({required this.kind, required this.color});

  final _ResultCornerKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: CustomPaint(
        painter: _ResultCornerPainter(kind: kind, color: color),
      ),
    );
  }
}

class _ResultCornerPainter extends CustomPainter {
  const _ResultCornerPainter({required this.kind, required this.color});

  final _ResultCornerKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    const radius = 4.0;
    const inset = 1.0;
    final path = Path();
    if (kind == _ResultCornerKind.bottomLeft) {
      path.moveTo(inset, inset);
      path.lineTo(inset, size.height - radius);
      path.arcToPoint(
        Offset(radius, size.height - inset),
        radius: const Radius.circular(radius - inset),
        clockwise: false,
      );
      path.lineTo(size.width - inset, size.height - inset);
    } else {
      path.moveTo(inset, size.height - inset);
      path.lineTo(size.width - radius, size.height - inset);
      path.arcToPoint(
        Offset(size.width - inset, size.height - radius),
        radius: const Radius.circular(radius - inset),
        clockwise: false,
      );
      path.lineTo(size.width - inset, inset);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ResultCornerPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
