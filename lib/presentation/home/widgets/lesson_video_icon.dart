import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class LessonVideoIcon extends StatelessWidget {
  const LessonVideoIcon({super.key});

  static const String _playBadgeAsset = 'assets/images/icon_lesson_play.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.incompleteTaskIconSize,
      height: AppSpacing.incompleteTaskIconSize,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.lessonVideoIconShell,
        borderRadius: BorderRadius.circular(AppRadius.smPlus),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        _playBadgeAsset,
        width: AppSpacing.lessonVideoBadgeWidth,
        height: AppSpacing.lessonVideoBadgeHeight,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}
