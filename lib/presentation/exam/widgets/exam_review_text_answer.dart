import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/answered_question_display.dart';
import '../../../data/quizzes/answered_question_models.dart';
import 'exam_review_answer_layout.dart';

class ExamReviewTextAnswer extends StatelessWidget {
  const ExamReviewTextAnswer({super.key, required this.question});

  final AnsweredQuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final studentLines = question.studentAnswerLines;
    final correctLines = question.correctAnswerLines;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: _ColumnHeader(
                  label: 'إجابتك',
                  barColor: AppColors.accentBg,
                  labelColor: AppColors.textMuted,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ColumnHeader(
                  label: 'الإجابة الصحيحة',
                  barColor: Color(0xFF34D399),
                  labelColor: Color(0xFF34D399),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: studentLines.isNotEmpty
                    ? Column(
                        children: [
                          for (final line in studentLines)
                            _TextTile(
                              text: line,
                              style: _studentAnswerStyle(
                                question: question,
                                studentLine: line,
                                correctLines: correctLines,
                              ),
                            ),
                        ],
                      )
                    : const _NoAnswerTile(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    for (final line in correctLines)
                      _TextTile(
                        text: line,
                        style: _TextTileStyle.answerKey,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.label,
    required this.barColor,
    required this.labelColor,
  });

  final String label;
  final Color barColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: AppTypography.badge.copyWith(
              color: labelColor,
              fontWeight: AppFonts.semibold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

enum _TextTileStyle {

  studentCorrect,

  studentWrong,

  answerKey,
}

/// Essay review must follow the API verdict (`is_correct`), not a local
/// string match — when dashboard option «جعل أي إجابة صحيحة» is on, the
/// student text can differ from the model answer and still be correct.
_TextTileStyle _studentAnswerStyle({
  required AnsweredQuizQuestion question,
  required String studentLine,
  required List<String> correctLines,
}) {
  if (question.type == 'essay') {
    return question.isCorrect
        ? _TextTileStyle.studentCorrect
        : _TextTileStyle.studentWrong;
  }

  final normalized = studentLine.toLowerCase().trim();
  final matches = correctLines.any((c) => c.toLowerCase().trim() == normalized);
  return matches ? _TextTileStyle.studentCorrect : _TextTileStyle.studentWrong;
}

class _TextTile extends StatelessWidget {
  const _TextTile({
    required this.text,
    required this.style,
  });

  final String text;
  final _TextTileStyle style;

  @override
  Widget build(BuildContext context) {

    final Color bg;
    final Color border;
    final List<BoxShadow> shadows;
    final bool showIcon;
    final bool isCorrectIcon;

    switch (style) {
      case _TextTileStyle.studentCorrect:
        bg = AppColors.cardGreenBg;
        border = AppColors.cardGreenBorder;
        shadows = const [
          BoxShadow(color: AppColors.cardGreenGlowOuter, blurRadius: 20),
        ];
        showIcon = true;
        isCorrectIcon = true;
      case _TextTileStyle.studentWrong:
        bg = AppColors.cardRedBg;
        border = AppColors.cardRedBorder;
        shadows = const [
          BoxShadow(color: AppColors.cardRedGlowOuter, blurRadius: 20),
        ];
        showIcon = true;
        isCorrectIcon = false;
      case _TextTileStyle.answerKey:
        bg = const Color(0x0D10B981);
        border = const Color(0x3310B981);
        shadows = const [
          BoxShadow(
            color: Color(0x0D10B981),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ];
        showIcon = false;
        isCorrectIcon = true;
    }

    final plain = QuizHtmlText.plainText(text);
    final textStyle = AppTypography.bodySm.copyWith(
      color: const Color(0xFFE5E7EB),
      height: 1.625,
    );

    Widget? icon;
    if (showIcon) {
      icon = Icon(
        isCorrectIcon ? Icons.check_rounded : Icons.close_rounded,
        size: 14,
        color: isCorrectIcon
            ? const Color(0xFF34D399)
            : const Color(0xFFF87171),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReviewHoverHighlight(
        scale: 1.02,
          builder: (context, highlighted) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
              border: Border.all(color: border),
              boxShadow: highlighted
                  ? [
                      ...shadows,
                      BoxShadow(
                        color: (isCorrectIcon
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withValues(alpha: 0.16),
                        blurRadius: 18,
                      ),
                    ]
                  : shadows,
            ),
            child: ReviewFlowingText(
              text: plain,
              style: textStyle,
              leading: icon,
            ),
          );
        },
      ),
    );
  }
}

class _NoAnswerTile extends StatelessWidget {
  const _NoAnswerTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12161F),
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(color: const Color(0xFF313648)),
      ),
      child: Column(
        children: [
          const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(height: 8),
          Text(
            'لم يتم تقديم إجابة',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
