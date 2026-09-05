import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/answers_direction.dart';
import '../../../core/widgets/quiz_html_text.dart';

/// Correct-answer panel for knowledge essay questions.
/// Green when the student was correct (or mark-all); red when wrong.
class KnowledgeEssayAnswerReveal extends StatelessWidget {
  const KnowledgeEssayAnswerReveal({
    super.key,
    required this.correctTitles,
    required this.useGreenTheme,
    this.answersDirection = AnswersDirection.rtl,
  });

  final Iterable<String> correctTitles;
  final bool useGreenTheme;
  final AnswersDirection answersDirection;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        useGreenTheme ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    final borderColor =
        useGreenTheme ? const Color(0x6622C55E) : const Color(0x66EF4444);
    final fillColor =
        useGreenTheme ? const Color(0x2614532D) : const Color(0x267F1D1D);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: AppRadius.borderTailwindXl,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'الإجابة الصحيحة:',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: labelColor,
              fontWeight: AppFonts.semibold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          for (final title in correctTitles)
            Text(
              QuizHtmlText.plainText(title),
              textAlign: answersDirection.textAlign,
              textDirection: answersDirection.textDirection,
              style: AppTypography.bodySm.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}
