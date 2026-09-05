import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_radius.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import 'lesson_mp4_html.dart';
import 'lesson_video_chrome.dart';
import 'lesson_video_fullscreen.dart';

class LessonMp4Player extends StatefulWidget {
  const LessonMp4Player({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.mimeType,
    this.lessonId,
    this.initialPositionSeconds = 0,
    this.onProgressUpdate,
    this.onWatched,
    this.onPlaybackEnded,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final String? mimeType;
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

  late final String _viewType;
  late final LessonPlaybackTracker _tracker;
  late final StallWatch _stall;
  web.HTMLVideoElement? _video;

  Timer? _hideTimer;
  var _started = false;
  var _playing = false;
  var _buffering = false;
  var _controlsVisible = true;
  var _seeking = false;
  var _muted = false;
  var _rate = 1.0;
  var _hasResumed = false;
  var _hasEnded = false;
  var _loading = true;
  String? _error;
  double _seekValue = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _viewType = 'lesson-mp4-${identityHashCode(this)}';
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    _stall = StallWatch(thresholdSeconds: 120, onStall: _reload)..start();
    unawaited(_tracker.resolve());

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final video = web.HTMLVideoElement()
        ..controls = false
        ..preload = 'none'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('controlslist', 'nodownload nofullscreen noremoteplayback');

      final source = web.HTMLSourceElement()
        ..src = VideoSource.networkUri(widget.videoUrl).toString()
        ..type = () {
          final mime = VideoSource.normalizeMime(widget.mimeType);
          return mime.isEmpty ? 'video/mp4' : mime;
        }();
      video.append(source);

      video.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..display = 'block'
        ..backgroundColor = '#000'
        ..borderRadius = '${AppRadius.tailwindXl}px'
        ..pointerEvents = 'none';
      video.style.setProperty('object-fit', 'contain');

      final poster = widget.thumbnailUrl;
      if (poster != null && poster.isNotEmpty) video.poster = poster;

      _video = video;
      _bind(video);
      return video;
    });
  }

  void _bind(web.HTMLVideoElement video) {
    video.addEventListener(
      'canplay',
      ((web.Event _) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = null;
          _duration = _durationOf(video);
        });
        _maybeResume();
        video.playbackRate = _rate;
        video.muted = _muted;
      }).toJS,
    );
    video.addEventListener(
      'waiting',
      ((web.Event _) {
        if (mounted) setState(() => _buffering = true);
      }).toJS,
    );
    video.addEventListener(
      'playing',
      ((web.Event _) {
        if (mounted) setState(() => _buffering = false);
      }).toJS,
    );
    video.addEventListener(
      'error',
      ((web.Event _) {
        if (!mounted) return;
        final code = switch (video.error?.code) {
          1 => 'aborted',
          2 => 'network',
          3 => 'decode',
          4 => 'src_not_supported',
          _ => 'unknown',
        };
        debugPrint('[LessonMp4:web] media error code=$code url=${widget.videoUrl}');
        setState(() {
          _loading = false;
          _error = LessonMp4Html.userMessageForError(code);
        });
      }).toJS,
    );
    video.addEventListener(
      'timeupdate',
      ((web.Event _) => _onTimeUpdate()).toJS,
    );
    video.addEventListener(
      'play',
      ((web.Event _) {
        _playing = true;
        _started = true;
        _tracker.onPlay();
        _stall.setPlaying(true);
        _scheduleHide();
        if (mounted) setState(() {});
      }).toJS,
    );
    video.addEventListener(
      'pause',
      ((web.Event _) {
        _playing = false;
        _tracker.onPause();
        _stall.setPlaying(false);
        _hideTimer?.cancel();
        _controlsVisible = true;
        if (mounted) setState(() {});
      }).toJS,
    );
    video.addEventListener(
      'ended',
      ((web.Event _) {
        if (_hasEnded) return;
        _hasEnded = true;
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
      }).toJS,
    );
  }

  @override
  void didUpdateWidget(covariant LessonMp4Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl == widget.videoUrl) return;
    final video = _video;
    if (video == null) return;
    _hasResumed = false;
    _hasEnded = false;
    _started = false;
    _playing = false;
    setState(() {
      _loading = true;
      _error = null;
    });
    while (video.firstChild != null) {
      video.removeChild(video.firstChild!);
    }
    final source = web.HTMLSourceElement()
      ..src = VideoSource.networkUri(widget.videoUrl).toString()
      ..type = () {
        final mime = VideoSource.normalizeMime(widget.mimeType);
        return mime.isEmpty ? 'video/mp4' : mime;
      }();
    video.append(source);
    final poster = widget.thumbnailUrl;
    if (poster != null && poster.isNotEmpty) video.poster = poster;
    video.load();
  }

  Duration _durationOf(web.HTMLVideoElement video) {
    final seconds = video.duration;
    if (!seconds.isFinite || seconds <= 0) return Duration.zero;
    return Duration(milliseconds: (seconds * 1000).round());
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
    _hasResumed = true;
    if (safe > 0) video.currentTime = safe.toDouble();
  }

  void _onTimeUpdate() {
    final video = _video;
    if (video == null || !mounted || _seeking) return;
    final duration = video.duration;
    if (!duration.isFinite || duration <= 0) return;
    final current = video.currentTime;
    final pct = ((current / duration) * 100).clamp(0, 100).round();
    widget.onProgressUpdate?.call(pct);
    _tracker.update(seconds: current.round(), duration: duration.round());
    _stall.reportTime(current);
    setState(() {
      _position = Duration(milliseconds: (current * 1000).round());
      _duration = Duration(milliseconds: (duration * 1000).round());
    });
  }

  void _reload() {
    final video = _video;
    if (video == null) return;
    final position = video.currentTime;
    setState(() {
      _error = null;
      _loading = true;
      _hasEnded = false;
    });
    video.load();
    video.addEventListener(
      'canplay',
      ((web.Event _) {
        if (position > 0) video.currentTime = position;
      }).toJS,
    );
  }

  void _togglePlay() {
    final video = _video;
    if (video == null) return;
    setState(() => _started = true);
    if (_playing) {
      video.pause();
    } else {
      unawaited(
        video.play().toDart.then((_) {}, onError: (_) {}),
      );
    }
    _showControls();
  }

  void _toggleMute() {
    final video = _video;
    if (video == null) return;
    setState(() => _muted = !_muted);
    video.muted = _muted;
    video.volume = _muted ? 0 : 1;
    _showControls();
  }

  void _setRate(double rate) {
    final video = _video;
    if (video == null) return;
    setState(() => _rate = rate);
    video.playbackRate = rate;
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
    if (!_playing) return;
    _hideTimer = Timer(_autoHide, () {
      if (mounted && _playing && !_seeking) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  Future<void> _toggleFullscreen() async {
    if (isBrowserFullscreen) {
      await exitBrowserFullscreen();
    } else {
      await enterBrowserFullscreen();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _stall.dispose();
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView(viewType: _viewType),
          LessonVideoChrome(
            started: _started,
            playing: _playing,
            buffering: _buffering,
            loading: _loading,
            controlsVisible: _controlsVisible,
            isFullscreen: isBrowserFullscreen,
            muted: _muted,
            playbackRate: _rate,
            position: _position,
            duration: _duration,
            seeking: _seeking,
            seekValue: _seekValue,
            thumbnailUrl: _started ? null : widget.thumbnailUrl,
            errorMessage: _error,
            onRetry: _reload,
            onTogglePlay: _togglePlay,
            onToggleControls: _toggleControls,
            onToggleMute: _toggleMute,
            onRateChanged: _setRate,
            onFullscreen: () => unawaited(_toggleFullscreen()),
            onSeekStart: (v) {
              _hideTimer?.cancel();
              setState(() {
                _seeking = true;
                _seekValue = v;
              });
            },
            onSeekChanged: (v) => setState(() => _seekValue = v),
            onSeekEnd: (v) {
              final video = _video;
              if (video != null) video.currentTime = v;
              setState(() {
                _seeking = false;
                _hasEnded = false;
                _position = Duration(milliseconds: (v * 1000).round());
              });
              unawaited(_tracker.sync());
              _scheduleHide();
            },
          ),
        ],
      ),
    );
  }
}
