import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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

  late final String _viewType;
  web.HTMLVideoElement? _video;
  Timer? _syncTimer;
  var _canTrack = false;
  var _hasResumed = false;
  var _hasEnded = false;
  var _lastSyncedSeconds = -1;
  var _isFullscreen = false;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'lesson-mp4-${identityHashCode(this)}';
    _resolveTracking();

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final video = web.HTMLVideoElement()
        ..src = widget.videoUrl
        ..controls = true
        ..preload = 'metadata'
        ..setAttribute('controlsList', 'nodownload')
        ..setAttribute('playsinline', 'true');

      video.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..display = 'block'
        ..backgroundColor = '#000'
        ..borderRadius = '${AppRadius.tailwindXl}px';
      video.style.setProperty('object-fit', 'contain');

      final poster = widget.thumbnailUrl;
      if (poster != null && poster.isNotEmpty) {
        video.poster = poster;
      }

      _video = video;

      video.addEventListener(
        'fullscreenchange',
        ((web.Event _) => _syncFullscreenState()).toJS,
      );
      video.addEventListener(
        'canplay',
        ((web.Event _) {
          if (mounted) setState(() => _hasError = false);
          _maybeResume();
        }).toJS,
      );
      video.addEventListener(
        'error',
        ((web.Event _) {
          if (mounted) setState(() => _hasError = true);
        }).toJS,
      );
      video.addEventListener(
        'timeupdate',
        ((web.Event _) => _onTimeUpdate()).toJS,
      );
      video.addEventListener(
        'pause',
        ((web.Event _) {
          unawaited(_syncProgress());
        }).toJS,
      );
      video.addEventListener(
        'ended',
        ((web.Event _) {
          if (!_hasEnded) {
            _hasEnded = true;
            unawaited(_syncProgress());
            widget.onPlaybackEnded?.call();
          }
        }).toJS,
      );
      video.addEventListener(
        'play',
        ((web.Event _) => _startSyncTimer()).toJS,
      );

      return video;
    });
  }

  @override
  void didUpdateWidget(covariant LessonMp4Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      final video = _video;
      if (video != null) {
        _hasResumed = false;
        _hasEnded = false;
        _lastSyncedSeconds = -1;
        setState(() => _hasError = false);
        video.src = widget.videoUrl;
        final poster = widget.thumbnailUrl;
        if (poster != null && poster.isNotEmpty) {
          video.poster = poster;
        }
        video.load();
      }
    }
  }

  Future<void> _resolveTracking() async {
    if (widget.lessonId == null) return;
    final user = await AuthSession.load();
    if (mounted && user?.role == 1) {
      setState(() => _canTrack = true);
    }
  }

  void _maybeResume() {
    final video = _video;
    if (video == null || _hasResumed || widget.initialPositionSeconds <= 0) {
      return;
    }

    final duration = video.duration.isFinite ? video.duration.round() : 0;
    final safe = VideoProgress.clampResumePosition(
      widget.initialPositionSeconds,
      duration,
    );
    if (safe <= 0) return;

    _hasResumed = true;
    video.currentTime = safe.toDouble();
  }

  void _onTimeUpdate() {
    final video = _video;
    if (video == null) return;
    final duration = video.duration;
    if (!duration.isFinite || duration <= 0) return;

    final pct = ((video.currentTime / duration) * 100).clamp(0, 100).round();
    widget.onProgressUpdate?.call(pct);
  }

  void _startSyncTimer() {
    _syncTimer ??= Timer.periodic(_syncInterval, (_) => _syncProgress());
  }

  Future<void> _syncProgress() async {
    if (!_canTrack) return;
    final video = _video;
    final lessonId = widget.lessonId;
    if (video == null || lessonId == null) return;

    final seconds = video.currentTime.round();
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

  void _syncFullscreenState() {
    final video = _video;
    if (video == null || !mounted) return;
    final active = isElementFullscreen(video);
    if (active != _isFullscreen) {
      setState(() => _isFullscreen = active);
    }
  }

  Future<void> _toggleFullscreen() async {
    final video = _video;
    if (video == null) return;

    if (_isFullscreen) {
      await exitBrowserFullscreen();
      return;
    }

    await requestWebElementFullscreen(video);
    _syncFullscreenState();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            HtmlElementView(viewType: _viewType),
            if (_hasError)
              const ColoredBox(
                color: Color(0xCC000000),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: LessonVideoFullscreenButton(
                isFullscreen: _isFullscreen,
                onPressed: () => unawaited(_toggleFullscreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
