import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_quiz_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_option_text.dart';
import '../models/luck_card_question.dart';

enum LuckAnswerVisualState { idle, correct, wrong, dimmed }

class LuckAnswerButton extends StatelessWidget {
  const LuckAnswerButton({
    super.key,
    required this.option,
    required this.index,
    required this.state,
    this.onTap,
    this.enterDelay = Duration.zero,
    this.compact = false,
  });

  final LuckAnswerOption option;
  final int index;
  final LuckAnswerVisualState state;
  final VoidCallback? onTap;
  final Duration enterDelay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppQuizPalette.knowledgeAnswerColor(index);
    final opacity = state == LuckAnswerVisualState.dimmed ? 0.35 : 1.0;
    final showOutline = state == LuckAnswerVisualState.correct ||
        state == LuckAnswerVisualState.wrong;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.examQuestionEnter,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value * opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderAnswerButton,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: AppDurations.luckFeedback,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: AppRadius.borderAnswerButton,
              border: showOutline
                  ? Border.all(color: AppColors.onDark, width: 2)
                  : null,
              boxShadow: AppQuizPalette.knowledgeAnswerShadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.xxs : AppSpacing.sm,
                    vertical: compact ? AppSpacing.xxs : AppSpacing.sm,
                  ),
                  child: QuizOptionText(
                    html: option.text,
                    textAlign: TextAlign.center,
                    baseStyle: AppTypography.headingDialog.copyWith(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      fontSize: compact ? 14 : 18,
                    ),
                  ),
                ),
                if (showOutline)
                  Positioned(
                    bottom: AppSpacing.sm,
                    child: state == LuckAnswerVisualState.correct
                        ? Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppQuizPalette.knowledgeAnswerBadgeFill,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.onDark,
                              size: 16,
                            ),
                          )
                        : const Text(
                            '✕',
                            style: TextStyle(
                              color: AppColors.onDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
