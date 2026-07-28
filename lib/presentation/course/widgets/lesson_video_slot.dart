import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class LessonVideoSlot extends StatelessWidget {
  const LessonVideoSlot({
    super.key,
    this.videoUrl,
    this.posterAsset = 'assets/images/lesson_video_poster.png',
  });

  final String? videoUrl;
  final String posterAsset;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: AppRadius.borderAnswerButton,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.scrim95,
            image: DecorationImage(
              image: AssetImage(posterAsset),
              fit: BoxFit.cover,
            ),
            boxShadow: AppShadows.xl,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (videoUrl == null)
                _PlayPlaceholder()
              else
                _VideoReadyPlaceholder(url: videoUrl!),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.overlayBlack35,
      child: Center(
        child: Container(
          width: AppSpacing.massive,
          height: AppSpacing.massive,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.overlayWhite10,
            border: Border.all(
              color: AppColors.onDarkMuted,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.onDark,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _VideoReadyPlaceholder extends StatelessWidget {
  const _VideoReadyPlaceholder({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.overlayBlack55,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Text(
            'جاهز لتشغيل الفيديو',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppTheme.muted),
          ),
        ),
      ),
    );
  }
}
