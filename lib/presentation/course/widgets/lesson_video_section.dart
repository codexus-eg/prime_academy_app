import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/courses/user_course.dart';
import 'lesson_embed_player.dart';
import 'lesson_mp4_player.dart';
import 'lesson_video_title_bar.dart';
import 'lesson_youtube_player.dart';

class LessonVideoSection extends StatelessWidget {
  const LessonVideoSection({
    super.key,
    required this.title,
    required this.kind,
    this.videoUrl,
    this.mimeType,
    this.thumbnailUrl,
    this.lessonId,
    this.initialPositionSeconds = 0,
    this.hasAccess = true,
    this.isLoadingVideo = false,
    this.onProgressUpdate,
    this.onWatched,
    this.onPlaybackEnded,
  });

  final String title;
  final LessonVideoKind kind;
  final String? videoUrl;
  final String? mimeType;
  final String? thumbnailUrl;

  final int? lessonId;
  final int initialPositionSeconds;
  final bool hasAccess;
  /// True while lesson playback metadata is still loading — must not show
  /// "unavailable" merely because [kind]/url are not ready yet.
  final bool isLoadingVideo;
  final ValueChanged<int>? onProgressUpdate;
  final VoidCallback? onWatched;
  final VoidCallback? onPlaybackEnded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: LessonVideoTitleBar(title: title),
        ),
        const SizedBox(height: AppSpacing.base),
        _buildPlayer(),
      ],
    );
  }

  Widget _buildPlayer() {
    if (!hasAccess) {
      return _placeholder(
        'لا يمكنك مشاهدة هذا الدرس، يرجى التسجيل في المادة أولاً.',
      );
    }

    final url = videoUrl;
    final missing =
        url == null || url.isEmpty || kind == LessonVideoKind.none;

    // Loading / initializing ≠ unavailable.
    if (missing) {
      if (isLoadingVideo) return _loadingPlaceholder();
      return _placeholder('الدرس غير متاح حالياً');
    }

    switch (kind) {
      case LessonVideoKind.mp4:
        return LessonMp4Player(
          videoUrl: url,
          mimeType: mimeType ?? 'video/mp4',
          thumbnailUrl: thumbnailUrl,
          lessonId: lessonId,
          initialPositionSeconds: initialPositionSeconds,
          onProgressUpdate: onProgressUpdate,
          onWatched: onWatched,
          onPlaybackEnded: onPlaybackEnded,
        );
      case LessonVideoKind.youtube:
        return LessonYoutubePlayer(
          videoUrl: url,
          thumbnailUrl: thumbnailUrl,
          lessonId: lessonId,
          initialPositionSeconds: initialPositionSeconds,
          onProgressUpdate: onProgressUpdate,
          onWatched: onWatched,
          onPlaybackEnded: onPlaybackEnded,
        );
      case LessonVideoKind.embed:
        return LessonEmbedPlayer(
          videoUrl: url,
          thumbnailUrl: thumbnailUrl,
          lessonId: lessonId,
          initialPositionSeconds: initialPositionSeconds,
          onProgressUpdate: onProgressUpdate,
          onWatched: onWatched,
          onPlaybackEnded: onPlaybackEnded,
        );
      case LessonVideoKind.none:
        return isLoadingVideo
            ? _loadingPlaceholder()
            : _placeholder('الدرس غير متاح حالياً');
    }
  }

  Widget _loadingPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.secondaryCard,
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.secondaryCard,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
