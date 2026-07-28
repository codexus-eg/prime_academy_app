import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class LessonEmbedPlayer extends StatelessWidget {
  const LessonEmbedPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: AppRadius.borderAnswerButton,
        child: ColoredBox(
          color: AppColors.secondaryCard,
          child: Center(
            child: TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(videoUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.play_circle_fill, color: AppColors.blue),
              label: Text(
                'تشغيل الفيديو',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
