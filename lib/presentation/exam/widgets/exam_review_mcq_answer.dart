import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_answer_image.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/answered_question_models.dart';
import '../../../data/quizzes/quiz_models.dart';
import 'exam_review_answer_layout.dart';

class ExamReviewMcqAnswer extends StatelessWidget {
  const ExamReviewMcqAnswer({super.key, required this.question});

  final AnsweredQuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final correctIds = question.correctAnswerIds.toSet();
    final studentIds = question.studentAnswerIds.toSet();

    final studentAnswers =
        question.answers.where((a) => studentIds.contains(a.id)).toList();
    final correctAnswers =
        question.answers.where((a) => correctIds.contains(a.id)).toList();

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
                child: studentAnswers.isNotEmpty
                    ? Column(
                        children: [
                          for (final answer in studentAnswers)
                            _AnswerTile(
                              answer: answer,
                              isCorrect: correctIds.contains(answer.id),
                            ),
                        ],
                      )
                    : const _NoAnswerTile(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    for (final answer in correctAnswers)
                      _AnswerTile(
                        answer: answer,
                        isCorrect: true,
                        showIcon: false,
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

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.answer,
    this.isCorrect = true,
    this.showIcon = true,
  });

  final QuizMcqAnswer answer;
  final bool isCorrect;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final title = answer.displayTitle.isNotEmpty
        ? answer.displayTitle
        : QuizHtmlText.plainText(answer.title);
    final hasImage = answer.imageUrl != null && answer.imageUrl!.isNotEmpty;
    final textStyle = AppTypography.bodySm.copyWith(
      color: const Color(0xFFE5E7EB),
      fontWeight: AppFonts.medium,
      height: 1.625,
    );

    Widget? icon;
    if (showIcon) {
      icon = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCorrect ? const Color(0x3310B981) : const Color(0x33EF4444),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCorrect ? Icons.check_rounded : Icons.close_rounded,
          size: 10,
          color: isCorrect ? const Color(0xFF34D399) : const Color(0xFFF87171),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ReviewHoverHighlight(
        scale: 1.02,
        builder: (context, highlighted) {
          final bg =
              isCorrect ? const Color(0x1A10B981) : const Color(0x1AEF4444);
          final border =
              isCorrect ? const Color(0x4D10B981) : const Color(0x4DEF4444);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: (isCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: highlighted ? 0.18 : 0.1),
                  blurRadius: highlighted ? 18 : 14,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title.isNotEmpty)
                  ReviewFlowingText(
                    text: title,
                    style: textStyle,
                    leading: icon,
                  )
                else if (icon != null)
                  Align(alignment: AlignmentDirectional.centerStart, child: icon),
                if (hasImage) ...[
                  if (title.isNotEmpty) const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 128),
                        child: QuizAnswerImage(
                          imageUrl: answer.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
        border: Border.all(
          color: const Color(0xFF313648),
          style: BorderStyle.solid,
        ),
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
