import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import 'lesson_video_chrome.dart';
import 'lesson_video_fullscreen.dart';
import 'lesson_youtube_chrome.dart';

class LessonYoutubePlayer extends StatefulWidget {
  const LessonYoutubePlayer({
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
  State<LessonYoutubePlayer> createState() => _LessonYoutubePlayerState();
}

class _LessonYoutubePlayerState extends State<LessonYoutubePlayer> {
  static const _autoHide = Duration(seconds: 3);

  static const _playerParams = YoutubePlayerParams(
    showControls: false,
    showFullscreenButton: false,
    strictRelatedVideos: true,
    enableCaption: false,
    showVideoAnnotations: false,
    enableKeyboard: false,
    playsInline: true,
    privacyEnhancedMode: true,
    pointerEvents: PointerEvents.none,
    origin: 'https://www.youtube-nocookie.com',
    color: 'red',
    interfaceLanguage: 'en',
  );

  static const _qualityOrder = [
    'highres',
    'hd1080',
    'hd720',
    'large',
    'medium',
    'small',
    'tiny',
    'auto',
  ];

  YoutubePlayerController? _controller;
  late final LessonPlaybackTracker _tracker;
  late final StallWatch _stall;
  late final String _videoId;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _hideTimer;

  var _started = false;
  var _pendingAutoplay = false;
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
  String? _quality;
  List<String> _qualities = const [];

  @override
  void initState() {
    super.initState();
    _videoId = VideoSource.extractYouTubeId(widget.videoUrl) ??
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ??
        '';
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    _stall = StallWatch(
      thresholdSeconds: 30,
      onStall: _reload,
    )..start();
    unawaited(_tracker.resolve());
    if (_videoId.isEmpty) {
      _loading = false;
      _error = 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.';
    } else {
      _bindController(_createController());
    }
  }

  YoutubePlayerController _createController({int? startSeconds}) {
    return YoutubePlayerController.fromVideoId(
      videoId: _videoId,
      autoPlay: false,
      params: _playerParams,
      startSeconds: startSeconds?.toDouble(),
    );
  }

  void _bindController(YoutubePlayerController controller) {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _controller?.close();
    _controller = controller;
    _subscriptions
      ..add(controller.stream.listen(_onValue))
      ..add(controller.videoStateStream.listen(_onVideoState));
    unawaited(_syncYoutubeChrome(playing: false));
  }

  void _reload() {
    if (_videoId.isEmpty) return;
    final start = _position.inSeconds;
    setState(() {
      _error = null;
      _loading = true;
      _hasEnded = false;
    });
    _bindController(_createController(startSeconds: start));
  }

  void _onValue(YoutubePlayerValue value) {
    if (!mounted) return;

    if (value.hasError) {
      setState(() {
        _loading = false;
        _error = 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.';
      });
      return;
    }

    final playing = value.playerState == PlayerState.playing;
    final buffering = value.playerState == PlayerState.buffering;
    final duration = value.metaData.duration;

    setState(() {
      _playing = playing;
      _buffering = buffering;
      _loading = false;
      _rate = value.playbackRate;
      if (value.playbackQuality != null) _quality = value.playbackQuality;
      if (duration > Duration.zero) _duration = duration;
      if (playing) _started = true;
    });

    _stall.setPlaying(playing);

    if (value.playerState == PlayerState.ended) {
      if (!_hasEnded) {
        _hasEnded = true;
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _bindController(_createController());
          setState(() {
            _started = false;
            _playing = false;
            _position = Duration.zero;
            _hasResumed = true;
            _controlsVisible = true;
          });
        });
      }
      return;
    }

    if (value.playerState == PlayerState.cued ||
        value.playerState == PlayerState.paused ||
        playing) {
      _maybeResumeAndAutoplay();
      unawaited(_preferHd720());
      unawaited(_loadQualities());
    }

    if (playing) {
      _tracker.onPlay();
      _scheduleHide();
    } else {
      _tracker.onPause();
      _hideTimer?.cancel();
      _controlsVisible = true;
    }

    unawaited(_syncYoutubeChrome(playing: playing));
  }

  Future<void> _preferHd720() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.webViewController.runJavaScript(
        "try { player.setPlaybackQuality('hd720'); } catch (e) {}",
      );
    } catch (_) {}
  }

  Future<void> _loadQualities() async {
    final controller = _controller;
    if (controller == null || _qualities.isNotEmpty) return;
    try {
      final raw = await controller.webViewController.runJavaScriptReturningResult(
        'JSON.stringify(player.getAvailableQualityLevels())',
      );
      final decoded = jsonDecode(raw.toString());
      final list = decoded is List
          ? decoded.map((e) => e.toString()).toList()
          : <String>[];
      if (list.isEmpty || !mounted) return;
      list.sort(
        (a, b) => _qualityOrder.indexOf(a).compareTo(_qualityOrder.indexOf(b)),
      );
      setState(() => _qualities = list);
    } catch (_) {}
  }

  void _maybeResumeAndAutoplay() {
    final controller = _controller;
    if (!_started || controller == null) return;

    if (!_hasResumed && widget.initialPositionSeconds > 0) {
      if (_duration == Duration.zero) return;
      final safe = VideoProgress.clampResumePosition(
        widget.initialPositionSeconds,
        _duration.inSeconds,
      );
      _hasResumed = true;
      if (safe > 0) {
        controller.seekTo(seconds: safe.toDouble(), allowSeekAhead: true);
        setState(() => _position = Duration(seconds: safe));
      }
    }

    if (_pendingAutoplay) {
      _pendingAutoplay = false;
      controller.playVideo();
    }
  }

  void _onVideoState(YoutubeVideoState state) {
    if (!mounted || _seeking) return;
    setState(() => _position = state.position);
    _stall.reportTime(state.position.inMilliseconds / 1000);
    if (_duration == Duration.zero) return;
    final pct =
        ((_position.inMilliseconds / _duration.inMilliseconds) * 100)
            .clamp(0, 100)
            .round();
    widget.onProgressUpdate?.call(pct);
    _tracker.update(
      seconds: _position.inSeconds,
      duration: _duration.inSeconds,
    );
  }

  String get _thumbnailUrl =>
      widget.thumbnailUrl ?? 'https://i.ytimg.com/vi/$_videoId/hqdefault.jpg';

  Future<void> _syncYoutubeChrome({required bool playing}) {
    final controller = _controller;
    if (controller == null) return Future.value();
    return hideYoutubeEmbedChrome(
      controller,
      playing: playing,
      thumbnailUrl: _thumbnailUrl,
    );
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (!_started) {
      setState(() {
        _started = true;
        _pendingAutoplay = true;
        _controlsVisible = true;
      });
      try {
        controller.playVideo();
      } catch (_) {}
      return;
    }
    if (_playing) {
      controller.pauseVideo();
    } else {
      controller.playVideo();
    }
    _showControls();
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    if (_muted) {
      unawaited(controller.mute());
    } else {
      unawaited(controller.unMute());
    }
    _showControls();
  }

  void _setRate(double rate) {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _rate = rate);
    unawaited(controller.setPlaybackRate(rate));
    _showControls();
  }

  void _setQuality(String quality) {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _quality = quality);
    unawaited(
      controller.webViewController.runJavaScript(
        "try { player.setPlaybackQuality('$quality'); } catch (e) {}",
      ),
    );
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

    final controller = _controller;
    if (!mounted || controller == null) return;

    if (isFullscreen) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    controller.pauseVideo();
    final startPos = _position.inSeconds;
    var finalPos = startPos;
    var finalMuted = _muted;
    var finalRate = _rate;

    await openLessonVideoFullscreenRoute(
      context,
      builder: (ctx) => _YoutubeFullscreenBody(
        videoId: _videoId,
        thumbnailUrl: _thumbnailUrl,
        startSeconds: startPos,
        muted: _muted,
        rate: _rate,
        onCloseState: (pos, muted, rate) {
          finalPos = pos;
          finalMuted = muted;
          finalRate = rate;
        },
      ),
    );

    if (!mounted) return;
    _muted = finalMuted;
    _rate = finalRate;
    if (_muted) {
      unawaited(controller.mute());
    } else {
      unawaited(controller.unMute());
    }
    unawaited(controller.setPlaybackRate(finalRate));
    controller.seekTo(seconds: finalPos.toDouble(), allowSeekAhead: true);
    setState(() => _position = Duration(seconds: finalPos));
  }

  Widget _chrome({required bool isFullscreen}) {
    return LessonVideoChrome(
      started: _started,
      playing: _playing,
      buffering: _buffering,
      loading: _loading,
      controlsVisible: _controlsVisible,
      isFullscreen: isFullscreen || (kIsWeb && isBrowserFullscreen),
      muted: _muted,
      playbackRate: _rate,
      position: _position,
      duration: _duration,
      seeking: _seeking,
      seekValue: _seekValue,
      thumbnailUrl: _thumbnailUrl,
      errorMessage: _error,
      onRetry: _reload,
      qualityLabel: _quality,
      qualities: _qualities,
      onQualityChanged: _qualities.isEmpty ? null : _setQuality,
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
        _controller?.seekTo(seconds: v, allowSeekAhead: true);
        setState(() {
          _seeking = false;
          _position = Duration(seconds: v.round());
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
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isFullscreen = kIsWeb && isBrowserFullscreen;

    return LessonVideoPlayerShell(
      child: controller == null
          ? _chrome(isFullscreen: isFullscreen)
          : YoutubePlayer(
              key: ObjectKey(controller),
              controller: controller,
              aspectRatio: 16 / 9,
              backgroundColor: Colors.black,
              enableFullScreenOnVerticalDrag: false,
              autoFullScreen: false,
              initParams: _playerParams,
              gestureRecognizers: const {},
              controlsBuilder: (context, fs) {
                return _chrome(isFullscreen: fs || isFullscreen);
              },
            ),
    );
  }
}

class _YoutubeFullscreenBody extends StatefulWidget {
  const _YoutubeFullscreenBody({
    required this.videoId,
    required this.thumbnailUrl,
    required this.startSeconds,
    required this.muted,
    required this.rate,
    required this.onCloseState,
  });

  final String videoId;
  final String thumbnailUrl;
  final int startSeconds;
  final bool muted;
  final double rate;
  final void Function(int position, bool muted, double rate) onCloseState;

  @override
  State<_YoutubeFullscreenBody> createState() => _YoutubeFullscreenBodyState();
}

class _YoutubeFullscreenBodyState extends State<_YoutubeFullscreenBody> {
  static const _autoHide = Duration(seconds: 3);
  static const _params = YoutubePlayerParams(
    showControls: false,
    showFullscreenButton: false,
    strictRelatedVideos: true,
    enableCaption: false,
    showVideoAnnotations: false,
    enableKeyboard: false,
    playsInline: true,
    privacyEnhancedMode: true,
    pointerEvents: PointerEvents.none,
    origin: 'https://www.youtube-nocookie.com',
    color: 'red',
    interfaceLanguage: 'en',
  );

  late final YoutubePlayerController _ctrl;
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _hideTimer;

  var _hasResumed = false;
  final _started = true;
  var _playing = false;
  var _buffering = false;
  var _controlsVisible = true;
  var _seeking = false;
  late var _muted = widget.muted;
  late var _rate = widget.rate;
  double _seekValue = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _position = Duration(seconds: widget.startSeconds);
    _ctrl = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: _params,
    );
    _subs
      ..add(_ctrl.stream.listen(_onValue))
      ..add(_ctrl.videoStateStream.listen(_onVideoState));
  }

  void _emit() =>
      widget.onCloseState(_position.inSeconds, _muted, _rate);

  void _onValue(YoutubePlayerValue value) {
    if (!mounted) return;
    final playing = value.playerState == PlayerState.playing;
    final dur = value.metaData.duration;
    setState(() {
      _playing = playing;
      _buffering = value.playerState == PlayerState.buffering;
      _rate = value.playbackRate;
      if (dur > Duration.zero) _duration = dur;
    });

    if (!_hasResumed && _duration > Duration.zero) {
      _hasResumed = true;
      if (widget.startSeconds > 0) {
        _ctrl.seekTo(
          seconds: widget.startSeconds.toDouble(),
          allowSeekAhead: true,
        );
      }
      if (_muted) unawaited(_ctrl.mute());
      unawaited(_ctrl.setPlaybackRate(_rate));
      _ctrl.playVideo();
    }

    if (playing) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
      _controlsVisible = true;
    }
    unawaited(
      hideYoutubeEmbedChrome(
        _ctrl,
        playing: playing,
        thumbnailUrl: widget.thumbnailUrl,
      ),
    );
    _emit();
  }

  void _onVideoState(YoutubeVideoState state) {
    if (!mounted || _seeking) return;
    setState(() => _position = state.position);
    _emit();
  }

  void _togglePlay() {
    if (_playing) {
      _ctrl.pauseVideo();
    } else {
      _ctrl.playVideo();
    }
    _showControls();
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

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _ctrl,
      aspectRatio: 16 / 9,
      backgroundColor: Colors.black,
      enableFullScreenOnVerticalDrag: false,
      autoFullScreen: false,
      initParams: _params,
      gestureRecognizers: const {},
      controlsBuilder: (context, isFullscreen) {
        return LessonVideoChrome(
          started: _started,
          playing: _playing,
          buffering: _buffering,
          controlsVisible: _controlsVisible,
          isFullscreen: true,
          muted: _muted,
          playbackRate: _rate,
          position: _position,
          duration: _duration,
          seeking: _seeking,
          seekValue: _seekValue,
          thumbnailUrl: widget.thumbnailUrl,
          onTogglePlay: _togglePlay,
          onToggleControls: () {
            if (_controlsVisible) {
              _hideTimer?.cancel();
              setState(() => _controlsVisible = false);
            } else {
              _showControls();
            }
          },
          onToggleMute: () {
            setState(() => _muted = !_muted);
            if (_muted) {
              unawaited(_ctrl.mute());
            } else {
              unawaited(_ctrl.unMute());
            }
            _emit();
            _showControls();
          },
          onRateChanged: (rate) {
            setState(() => _rate = rate);
            unawaited(_ctrl.setPlaybackRate(rate));
            _emit();
            _showControls();
          },
          onFullscreen: () => Navigator.of(context).pop(),
          onSeekStart: (v) {
            _hideTimer?.cancel();
            setState(() {
              _seeking = true;
              _seekValue = v;
            });
          },
          onSeekChanged: (v) => setState(() => _seekValue = v),
          onSeekEnd: (v) {
            _ctrl.seekTo(seconds: v, allowSeekAhead: true);
            setState(() {
              _seeking = false;
              _position = Duration(seconds: v.round());
            });
            _emit();
            _scheduleHide();
          },
        );
      },
    );
  }
}
