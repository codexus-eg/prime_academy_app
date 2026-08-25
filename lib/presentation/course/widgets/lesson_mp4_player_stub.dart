import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import 'lesson_video_chrome.dart';
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
  static const _autoHide = Duration(seconds: 3);

  VideoPlayerController? _controller;
  late final LessonPlaybackTracker _tracker;
  late final StallWatch _stall;

  Timer? _hideTimer;
  var _generation = 0;
  var _started = false;
  var _controlsVisible = true;
  var _seeking = false;
  var _muted = false;
  var _rate = 1.0;
  var _lastPlaying = false;
  var _hasResumed = false;
  var _hasEnded = false;
  var _loading = true;
  String? _error;
  double _seekValue = 0;

  @override
  void initState() {
    super.initState();
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    _stall = StallWatch(
      thresholdSeconds: 120,
      onStall: _reload,
    )..start();
    unawaited(_tracker.resolve());
    _createController();
  }

  @override
  void didUpdateWidget(covariant LessonMp4Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _hasResumed = false;
      _hasEnded = false;
      _started = false;
      _createController();
    }
  }

  void _createController() {
    final previous = _controller;
    previous?.removeListener(_onControllerUpdate);
    unawaited(previous?.dispose());

    setState(() {
      _loading = true;
      _error = null;
      _controller = null;
    });

    final generation = ++_generation;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    controller.initialize().then((_) {
      if (!mounted || generation != _generation) return;
      setState(() => _loading = false);
      _maybeResume();
      unawaited(controller.setPlaybackSpeed(_rate));
      unawaited(controller.setVolume(_muted ? 0 : 1));
    }).catchError((Object error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.';
      });
    });
  }

  void _reload() {
    final position = _controller?.value.position.inSeconds ?? 0;
    _hasResumed = false;
    _createController();
    if (position > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller?.seekTo(Duration(seconds: position));
      });
    }
  }

  void _maybeResume() {
    final controller = _controller;
    if (_hasResumed ||
        widget.initialPositionSeconds <= 0 ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    final duration = controller.value.duration.inSeconds;
    final safe = VideoProgress.clampResumePosition(
      widget.initialPositionSeconds,
      duration,
    );
    _hasResumed = true;
    if (safe > 0) unawaited(controller.seekTo(Duration(seconds: safe)));
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;

    if (value.hasError) {
      setState(() {
        _error = 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.';
      });
      return;
    }

    if (value.isInitialized) {
      final duration = value.duration.inMilliseconds;
      if (duration > 0) {
        final pct = ((value.position.inMilliseconds / duration) * 100)
            .clamp(0, 100)
            .round();
        widget.onProgressUpdate?.call(pct);
        _tracker.update(
          seconds: value.position.inSeconds,
          duration: value.duration.inSeconds,
        );
        _stall.reportTime(value.position.inMilliseconds / 1000);
      }
    }

    _stall.setPlaying(value.isPlaying);
    if (value.isPlaying != _lastPlaying) {
      _lastPlaying = value.isPlaying;
      if (value.isPlaying) {
        _tracker.onPlay();
        _scheduleHide();
      } else {
        _tracker.onPause();
        _hideTimer?.cancel();
        _controlsVisible = true;
      }
    }

    if (value.position >= value.duration && value.duration > Duration.zero) {
      if (!_hasEnded) {
        _hasEnded = true;
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
      }
    }

    setState(() {});
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _started = true);
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    } else {
      unawaited(controller.play());
    }
    _showControls();
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    unawaited(controller.setVolume(_muted ? 0 : 1));
    _showControls();
  }

  void _setRate(double rate) {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _rate = rate);
    unawaited(controller.setPlaybackSpeed(rate));
    _showControls();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    final playing = _controller?.value.isPlaying ?? false;
    if (!playing) return;
    _hideTimer = Timer(_autoHide, () {
      if (mounted && (_controller?.value.isPlaying ?? false) && !_seeking) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  Future<void> _toggleFullscreen(bool isFullscreen) async {
    if (kIsWeb) {
      if (isFullscreen) {
        await exitBrowserFullscreen();
      } else {
        await enterBrowserFullscreen();
      }
      if (mounted) setState(() {});
      return;
    }

    if (!mounted) return;
    if (isFullscreen) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    await openLessonVideoFullscreenRoute(
      context,
      builder: (context) => _Mp4FullscreenView(
        controller: _controller!,
        chrome: (isFullscreen) => _chrome(isFullscreen: true),
      ),
    );
    if (mounted) _showControls();
  }

  Widget _chrome({required bool isFullscreen}) {
    final value = _controller?.value;
    final position = value?.position ?? Duration.zero;
    final duration = value?.duration ?? Duration.zero;
    return LessonVideoChrome(
      started: _started,
      playing: value?.isPlaying ?? false,
      buffering: value?.isBuffering ?? false,
      loading: _loading,
      controlsVisible: _controlsVisible,
      isFullscreen: isFullscreen || (kIsWeb && isBrowserFullscreen),
      muted: _muted,
      playbackRate: _rate,
      position: position,
      duration: duration,
      seeking: _seeking,
      seekValue: _seekValue,
      thumbnailUrl: _started ? null : widget.thumbnailUrl,
      errorMessage: _error,
      onRetry: _reload,
      onTogglePlay: _togglePlay,
      onToggleControls: _toggleControls,
      onToggleMute: _toggleMute,
      onRateChanged: _setRate,
      onFullscreen: () => unawaited(_toggleFullscreen(isFullscreen)),
      onSeekStart: (v) {
        _hideTimer?.cancel();
        setState(() {
          _seeking = true;
          _seekValue = v;
        });
      },
      onSeekChanged: (v) => setState(() => _seekValue = v),
      onSeekEnd: (v) {
        unawaited(_controller?.seekTo(Duration(milliseconds: (v * 1000).round())));
        setState(() {
          _seeking = false;
          _hasEnded = false;
        });
        unawaited(_tracker.sync());
        _scheduleHide();
      },
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _stall.dispose();
    _tracker.dispose();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final isFullscreen = kIsWeb && isBrowserFullscreen;

    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          _chrome(isFullscreen: isFullscreen),
        ],
      ),
    );
  }
}

class _Mp4FullscreenView extends StatelessWidget {
  const _Mp4FullscreenView({
    required this.controller,
    required this.chrome,
  });

  final VideoPlayerController controller;
  final Widget Function(bool isFullscreen) chrome;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio:
                      value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            chrome(true),
          ],
        );
      },
    );
  }
}
