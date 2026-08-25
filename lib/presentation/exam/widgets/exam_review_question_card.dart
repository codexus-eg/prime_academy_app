import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/answered_question_models.dart';
import 'exam_review_answer_layout.dart';
import 'exam_review_mcq_answer.dart';
import 'exam_review_text_answer.dart';
import 'exam_review_type_badge.dart';

class ExamReviewQuestionCard extends StatelessWidget {
  const ExamReviewQuestionCard({
    super.key,
    required this.question,
    required this.index,
  });

  final AnsweredQuizQuestion question;
  final int index;

  @override
  Widget build(BuildContext context) {
    final q = question;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ReviewHoverHighlight(
        builder: (context, highlighted) {
          final borderColor =
              highlighted ? const Color(0xFF2072E0) : const Color(0xFF313648);
          final shadowColor =
              highlighted ? const Color(0x262072E0) : const Color(0x1A000000);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF12161F),
              borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: highlighted ? 30 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (q.teacherReview?.text?.isNotEmpty == true) ...[
                    _TeacherReviewBox(text: q.teacherReview!.text!),
                    const SizedBox(height: AppSpacing.base),
                  ],
                  _QuestionHeader(question: q, index: index),
                  if (q.plainTitle.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ReviewTitle(text: q.plainTitle),
                  ],
                  if (q.isPassage && q.childQuestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...q.childQuestions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ExamReviewQuestionCard(
                              question: entry.value,
                              index: entry.key,
                            ),
                          ),
                        ),
                  ] else if (q.isMcq) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF313648), height: 1),
                    const SizedBox(height: 16),
                    ExamReviewMcqAnswer(question: q),
                  ] else if (!q.isPassage) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF313648), height: 1),
                    const SizedBox(height: 16),
                    ExamReviewTextAnswer(question: q),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question, required this.index});

  final AnsweredQuizQuestion question;
  final int index;

  @override
  Widget build(BuildContext context) {
    final q = question;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IndexBadge(index: index),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExamReviewTypeBadge(type: q.type),
                  if (!q.isPassage) ...[
                    const SizedBox(width: 8),
                    _CorrectnessBadge(isCorrect: q.isCorrect),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!q.isPassage) ...[
          const SizedBox(width: 8),
          _PointsBadge(
            awarded: q.awardedPoints,
            total: q.points,
          ),
        ],
      ],
    );
  }
}

class _ReviewTitle extends StatelessWidget {
  const _ReviewTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ReviewFlowingText(
      text: text,
      style: AppTypography.bodyMd.copyWith(
        color: const Color(0xFFE5E7EB),
        fontWeight: AppFonts.medium,
        height: 1.625,
        fontSize: 16,
      ),
    );
  }
}

class _TeacherReviewBox extends StatelessWidget {
  const _TeacherReviewBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x142072E0),
          borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
          border: const Border(

            left: BorderSide(color: Color(0xFF2072E0), width: 4),
            top: BorderSide(color: Color(0x332072E0)),
            right: BorderSide(color: Color(0x332072E0)),
            bottom: BorderSide(color: Color(0x332072E0)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x262072E0),
                borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
              ),
              child: const Icon(
                Icons.message_rounded,
                size: 16,
                color: Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ملاحظات المعلم',
                        style: AppTypography.bodySm.copyWith(
                          color: const Color(0xFF93C5FD),
                          fontWeight: AppFonts.semibold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x332072E0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Teacher Review',
                          style: AppTypography.badge.copyWith(
                            color: const Color(0xFF60A5FA),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: QuizHtmlText.detectTextDirection(text),
                    child: Text(
                      text,
                      style: AppTypography.bodySm.copyWith(
                        color: const Color(0xFFBFDBFE),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2130),
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(color: const Color(0xFF313648)),
      ),
      child: Text(
        '#${index + 1}',
        style: AppTypography.badge.copyWith(
          color: AppColors.textMuted,
          fontWeight: AppFonts.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CorrectnessBadge extends StatelessWidget {
  const _CorrectnessBadge({required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0x261B693D)
            : const Color(0x267F1D1D),
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(
          color: isCorrect
              ? const Color(0x4D1B693D)
              : const Color(0x4D7F1D1D),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            size: 10,
            color:
                isCorrect ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
          ),
          const SizedBox(width: 6),
          Text(
            isCorrect ? 'Correct' : 'Incorrect',
            style: AppTypography.badge.copyWith(
              color:
                  isCorrect ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
              fontWeight: AppFonts.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.awarded, required this.total});

  final int awarded;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2130),
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(color: const Color(0xFF313648)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'النقاط:',
            style: AppTypography.badge.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$awarded',
            style: AppTypography.bodySm.copyWith(
              color: const Color(0xFFE5E7EB),
              fontWeight: AppFonts.bold,
            ),
          ),
          Text(
            ' / ',
            style: AppTypography.badge.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          Text(
            '$total',
            style: AppTypography.badge.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
