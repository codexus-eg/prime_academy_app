import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/video_progress.dart';
import '../../../data/auth/auth_session.dart';
import '../../../data/courses/courses_api.dart';
import 'lesson_video_fullscreen.dart';

class LessonMp4Player extends StatefulWidget {
  const LessonMp4Player({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.lessonId,
    this.initialPositionSeconds = 0,
    this.onProgressUpdate,
    this.onWatched,
    this.onPlaybackEnded,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final int? lessonId;
  final int initialPositionSeconds;
  final ValueChanged<int>? onProgressUpdate;
  final VoidCallback? onWatched;
  final VoidCallback? onPlaybackEnded;

  @override
  State<LessonMp4Player> createState() => _LessonMp4PlayerState();
}

class _LessonMp4PlayerState extends State<LessonMp4Player> {
  static const _syncInterval = Duration(seconds: 10);

  late VideoPlayerController _controller;
  Timer? _syncTimer;
  var _initialized = false;
  var _showControls = true;
  var _canTrack = false;
  var _hasResumed = false;
  var _hasEnded = false;
  var _lastSyncedSeconds = -1;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) async {
        if (!mounted) return;
        setState(() => _initialized = true);
        _maybeResume();
      }).catchError((Object error) {
        if (!mounted) return;
        setState(() => _error = error);
      });
    _controller.addListener(_onControllerUpdate);
    _resolveTracking();
  }

  Future<void> _resolveTracking() async {
    if (widget.lessonId == null) return;
    final user = await AuthSession.load();
    if (mounted && user?.role == 1) {
      setState(() => _canTrack = true);
    }
  }

  void _maybeResume() {
    if (_hasResumed || widget.initialPositionSeconds <= 0 || !_initialized) {
      return;
    }

    final duration = _controller.value.duration.inSeconds;
    final safe = VideoProgress.clampResumePosition(
      widget.initialPositionSeconds,
      duration,
    );
    if (safe <= 0) return;

    _hasResumed = true;
    _controller.seekTo(Duration(seconds: safe));
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    final value = _controller.value;
    if (value.isInitialized) {
      final duration = value.duration.inMilliseconds;
      if (duration > 0) {
        final pct = ((value.position.inMilliseconds / duration) * 100)
            .clamp(0, 100)
            .round();
        widget.onProgressUpdate?.call(pct);
      }
    }

    if (value.isPlaying) {
      _startSyncTimer();
    } else {
      _stopSyncTimer();
      _syncProgress();
    }

    if (value.position >= value.duration && value.duration > Duration.zero) {
      if (!_hasEnded) {
        _hasEnded = true;
        _syncProgress();
        widget.onPlaybackEnded?.call();
      }
    }

    setState(() {});
  }

  void _startSyncTimer() {
    _syncTimer ??= Timer.periodic(_syncInterval, (_) {
      if (_controller.value.isPlaying) _syncProgress();
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncProgress() async {
    if (!_canTrack || !_controller.value.isInitialized) return;
    final lessonId = widget.lessonId;
    if (lessonId == null) return;

    final seconds = _controller.value.position.inSeconds;
    if (seconds == _lastSyncedSeconds) return;
    _lastSyncedSeconds = seconds;

    try {
      final watched = await CoursesApi.saveVideoProgress(
        lessonId: lessonId,
        progressSeconds: seconds,
      );
      if (watched) widget.onWatched?.call();
    } catch (_) {}
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showControls = true;
      } else {
        _controller.play();
        _showControls = false;
      }
    });
  }

  Future<void> _openFullscreen() async {
    if (!_initialized) return;
    await openLessonVideoFullscreenRoute(
      context,
      builder: (context) => _Mp4FullscreenView(controller: _controller),
    );
    if (mounted) setState(() => _showControls = true);
  }

  @override
  void dispose() {
    _stopSyncTimer();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: AppRadius.borderProfileCourse,
        child: ColoredBox(
          color: Colors.black,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return const Center(
        child: Text(
          'تعذّر تشغيل الفيديو',
          style: TextStyle(color: AppColors.onDark),
        ),
      );
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          if (_showControls || !_controller.value.isPlaying)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: IconButton(
                iconSize: 56,
                color: Colors.white,
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                onPressed: _togglePlay,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.blue,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 28,
            child: LessonVideoFullscreenButton(
              onPressed: () => unawaited(_openFullscreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mp4FullscreenView extends StatelessWidget {
  const _Mp4FullscreenView({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onTap: () {
            if (value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              if (!value.isPlaying)
                IconButton(
                  iconSize: 72,
                  color: Colors.white,
                  onPressed: controller.play,
                  icon: const Icon(Icons.play_circle_fill),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.blue,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
