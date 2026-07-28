import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/video_progress.dart';
import '../../../data/auth/auth_session.dart';
import '../../../data/courses/courses_api.dart';
import 'lesson_video_fullscreen.dart';

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
  static const _syncInterval = Duration(seconds: 10);
  static const _skipSeconds = 10;
  static const _playerRadius = BorderRadius.all(
    Radius.circular(AppRadius.tailwind3xl),
  );

  static const _playerParams = YoutubePlayerParams(
    showControls: false,

    showFullscreenButton: true,
    strictRelatedVideos: true,
    enableCaption: false,
    showVideoAnnotations: false,
    enableKeyboard: false,
    playsInline: true,
    privacyEnhancedMode: true,

    pointerEvents: PointerEvents.none,
    origin: 'https://www.youtube-nocookie.com',
    color: 'white',
    interfaceLanguage: 'ar',
  );

  late final YoutubePlayerController _controller;
  late final String _videoId;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _hideTimer;
  Timer? _syncTimer;

  var _started = false;
  var _pendingAutoplay = false;
  var _playing = false;
  var _controlsVisible = true;
  var _seeking = false;
  double _seekValue = 0;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  var _canTrack = false;
  var _lastSyncedSeconds = -1;
  var _hasResumed = false;
  var _hasEnded = false;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoId,
      autoPlay: false,
      params: _playerParams,
    );

    _subscriptions.add(_controller.stream.listen(_onValue));
    _subscriptions.add(_controller.videoStateStream.listen(_onVideoState));

    _resolveTracking();
  }

  Future<void> _resolveTracking() async {
    if (widget.lessonId == null) return;
    final user = await AuthSession.load();
    if (mounted && user?.role == 1) {
      setState(() => _canTrack = true);
    }
  }

  void _onValue(YoutubePlayerValue value) {
    if (!mounted) return;

    final playing = value.playerState == PlayerState.playing;
    final duration = value.metaData.duration;

    setState(() {
      _playing = playing;
      if (duration > Duration.zero) _duration = duration;
      if (playing) _started = true;
    });

    if (value.playerState == PlayerState.ended) {
      if (!_hasEnded) {
        _hasEnded = true;
        _syncProgress();
        widget.onPlaybackEnded?.call();
      }
      _showControls();
    }

    if (value.playerState == PlayerState.cued ||
        value.playerState == PlayerState.paused ||
        playing) {
      _maybeResumeAndAutoplay();
    }

    if (playing) {
      _startSyncTimer();
      _scheduleHide();
    } else {
      _stopSyncTimer();
      _syncProgress();
    }
  }

  void _maybeResumeAndAutoplay() {
    if (!_started) return;

    if (!_hasResumed && widget.initialPositionSeconds > 0) {
      if (_duration == Duration.zero) return;

      final safe = VideoProgress.clampResumePosition(
        widget.initialPositionSeconds,
        _duration.inSeconds,
      );
      _hasResumed = true;
      if (safe > 0) {
        _controller.seekTo(seconds: safe.toDouble(), allowSeekAhead: true);
        setState(() => _position = Duration(seconds: safe));
      }
    }

    if (_pendingAutoplay) {
      _pendingAutoplay = false;
      _controller.playVideo();
    }
  }

  void _onVideoState(YoutubeVideoState state) {
    if (!mounted || _seeking) return;
    setState(() => _position = state.position);
    _emitProgress();
  }

  void _emitProgress() {
    if (_duration == Duration.zero) return;
    final pct =
        ((_position.inMilliseconds / _duration.inMilliseconds) * 100)
            .clamp(0, 100)
            .round();
    widget.onProgressUpdate?.call(pct);
  }

  void _startSyncTimer() {
    _syncTimer ??= Timer.periodic(_syncInterval, (_) {
      if (_playing) _syncProgress();
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncProgress() async {
    if (!_canTrack) return;
    final lessonId = widget.lessonId;
    if (lessonId == null || _duration == Duration.zero) return;

    final seconds = _position.inSeconds;
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

  void _activatePlayer({required bool autoplay}) {
    setState(() {
      _started = true;
      _pendingAutoplay = autoplay;
      _controlsVisible = true;
    });

    if (autoplay) {
      try {
        _controller.playVideo();
      } catch (_) {}
    }
  }

  void _togglePlay() {
    if (!_started) {
      _activatePlayer(autoplay: true);
      return;
    }

    if (_playing) {
      _controller.pauseVideo();
    } else {
      _controller.playVideo();
    }
    _showControls();
  }

  void _seekRelative(int deltaSeconds) {
    if (_duration == Duration.zero) return;
    final target = (_position.inSeconds + deltaSeconds)
        .clamp(0, _duration.inSeconds)
        .toDouble();
    _controller.seekTo(seconds: target, allowSeekAhead: true);
    setState(() => _position = Duration(seconds: target.round()));
    _syncProgress();
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
        _controller.exitFullScreen();
      } else {
        _controller.enterFullScreen();
        _showControls();
      }
      return;
    }

    if (!mounted) return;
    _controller.pauseVideo();
    final startPos = _position.inSeconds;
    int finalPos = startPos;

    await openLessonVideoFullscreenRoute(
      context,
      builder: (ctx) => _MobileFullscreenBody(
        videoId: _videoId,
        startSeconds: startPos,
        onPosition: (pos) => finalPos = pos,
      ),
    );

    if (mounted) {
      _controller.seekTo(seconds: finalPos.toDouble(), allowSeekAhead: true);
      setState(() => _position = Duration(seconds: finalPos));
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _stopSyncTimer();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _controller.close();
    super.dispose();
  }

  Widget _buildControls({required bool isFullscreen}) {
    return _ControlsOverlay(
      visible: _controlsVisible,
      started: _started,
      playing: _playing,
      position: _position,
      duration: _duration,
      seekValue: _seekValue,
      seeking: _seeking,
      isFullscreen: isFullscreen,
      thumbnailUrl:
          widget.thumbnailUrl ??
          'https://i.ytimg.com/vi/$_videoId/hqdefault.jpg',
      onTapVideo: _toggleControls,
      onTogglePlay: _togglePlay,
      onSkipBack: () => _seekRelative(-_skipSeconds),
      onSkipForward: () => _seekRelative(_skipSeconds),
      onSeekStart: (v) {
        _hideTimer?.cancel();
        setState(() {
          _seeking = true;
          _seekValue = v;
        });
      },
      onSeekChanged: (v) => setState(() => _seekValue = v),
      onSeekEnd: (v) {
        _controller.seekTo(seconds: v, allowSeekAhead: true);
        setState(() {
          _seeking = false;
          _position = Duration(seconds: v.round());
        });
        _syncProgress();
        _scheduleHide();
      },
      onFullscreen: () {
        unawaited(_toggleFullscreen(isFullscreen));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _playerRadius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _started
            ? YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
                backgroundColor: Colors.black,
                enableFullScreenOnVerticalDrag: false,
                autoFullScreen: false,
                initParams: _playerParams,
                gestureRecognizers: const {},

                controlsBuilder: (context, isFullscreen) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildControls(isFullscreen: isFullscreen),
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        child: _YoutubeBrandMask(),
                      ),
                    ],
                  );
                },
              )
            : _Poster(
                thumbnailUrl:
                    widget.thumbnailUrl ??
                    'https://i.ytimg.com/vi/$_videoId/hqdefault.jpg',
                onPlay: () => _activatePlayer(autoplay: true),
              ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.visible,
    required this.started,
    required this.playing,
    required this.position,
    required this.duration,
    required this.seekValue,
    required this.seeking,
    required this.isFullscreen,
    required this.thumbnailUrl,
    required this.onTapVideo,
    required this.onTogglePlay,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onFullscreen,
  });

  final bool visible;
  final bool started;
  final bool playing;
  final Duration position;
  final Duration duration;
  final double seekValue;
  final bool seeking;
  final bool isFullscreen;
  final String thumbnailUrl;
  final VoidCallback onTapVideo;
  final VoidCallback onTogglePlay;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return _Poster(thumbnailUrl: thumbnailUrl, onPlay: onTogglePlay);
    }

    final totalSeconds = duration.inMilliseconds / 1000;
    final currentSeconds =
        seeking ? seekValue : position.inMilliseconds / 1000;
    final maxSeconds = totalSeconds <= 0 ? 1.0 : totalSeconds;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTapVideo,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !visible,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundIconButton(
                          icon: Icons.replay_10_rounded,
                          size: isFullscreen ? 40 : 32,
                          onTap: onSkipBack,
                        ),
                        const SizedBox(width: 16),
                        _RoundIconButton(
                          icon: playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: isFullscreen ? 64 : 56,
                          onTap: onTogglePlay,
                        ),
                        const SizedBox(width: 16),
                        _RoundIconButton(
                          icon: Icons.forward_10_rounded,
                          size: isFullscreen ? 40 : 32,
                          onTap: onSkipForward,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 4,
                    child: Row(
                      children: [
                        Text(
                          _fmt(currentSeconds.round()),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onDark,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: AppColors.blue,
                              inactiveTrackColor: AppColors.onDarkSubtle,
                              thumbColor: AppColors.blue,
                              overlayColor: AppColors.blueLightGlow10,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: currentSeconds.clamp(0, maxSeconds),
                              max: maxSeconds,
                              onChangeStart: onSeekStart,
                              onChanged: onSeekChanged,
                              onChangeEnd: onSeekEnd,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(duration.inSeconds),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _RoundIconButton(
                          icon: isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          size: 24,
                          onTap: onFullscreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _fmt(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

class _YoutubeBrandMask extends StatelessWidget {
  const _YoutubeBrandMask();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(

        width: 140,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF000000), Color(0x99000000), Color(0x00000000)],
            stops: [0, 0.6, 1],
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.thumbnailUrl, required this.onPlay});

  final String thumbnailUrl;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: Colors.black),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x40000000)),
          ),
          Center(
            child: _RoundIconButton(
              icon: Icons.play_arrow_rounded,
              size: 64,
              onTap: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(size * 0.14),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.scrim80,
          ),
          child: Icon(icon, color: AppColors.onDark, size: size),
        ),
      ),
    );
  }
}

class _MobileFullscreenBody extends StatefulWidget {
  const _MobileFullscreenBody({
    required this.videoId,
    required this.startSeconds,
    required this.onPosition,
  });

  final String videoId;
  final int startSeconds;

  final ValueChanged<int> onPosition;

  @override
  State<_MobileFullscreenBody> createState() => _MobileFullscreenBodyState();
}

class _MobileFullscreenBodyState extends State<_MobileFullscreenBody> {
  static const _autoHide = Duration(seconds: 3);
  static const _skipSeconds = 10;

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
    color: 'white',
    interfaceLanguage: 'ar',
  );

  late final YoutubePlayerController _ctrl;
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _hideTimer;

  var _hasResumed = false;
  var _playing = false;
  var _controlsVisible = true;
  var _seeking = false;
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

  void _onValue(YoutubePlayerValue value) {
    if (!mounted) return;
    final playing = value.playerState == PlayerState.playing;
    final dur = value.metaData.duration;

    setState(() {
      _playing = playing;
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
      _ctrl.playVideo();
    }

    if (playing) _scheduleHide();
  }

  void _onVideoState(YoutubeVideoState state) {
    if (!mounted || _seeking) return;
    setState(() => _position = state.position);
    widget.onPosition(state.position.inSeconds);
  }

  void _togglePlay() {
    if (_playing) {
      _ctrl.pauseVideo();
    } else {
      _ctrl.playVideo();
    }
    _showControls();
  }

  void _seekRelative(int delta) {
    if (_duration == Duration.zero) return;
    final t = (_position.inSeconds + delta)
        .clamp(0, _duration.inSeconds)
        .toDouble();
    _ctrl.seekTo(seconds: t, allowSeekAhead: true);
    setState(() => _position = Duration(seconds: t.round()));
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
    final totalSecs = _duration.inMilliseconds / 1000;
    final currentSecs =
        _seeking ? _seekValue : _position.inMilliseconds / 1000;
    final maxSecs = totalSecs <= 0 ? 1.0 : totalSecs;

    return YoutubePlayer(
      controller: _ctrl,
      aspectRatio: 16 / 9,
      backgroundColor: Colors.black,
      enableFullScreenOnVerticalDrag: false,
      autoFullScreen: false,
      initParams: _params,
      gestureRecognizers: const {},
      controlsBuilder: (context, isFullscreen) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildOverlay(currentSecs, maxSecs),
            const Positioned(
              bottom: 0,
              left: 0,
              child: _YoutubeBrandMask(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(double currentSecs, double maxSecs) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
              child: Stack(
                children: [

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundIconButton(
                          icon: Icons.replay_10_rounded,
                          size: 40,
                          onTap: () => _seekRelative(-_skipSeconds),
                        ),
                        const SizedBox(width: 16),
                        _RoundIconButton(
                          icon: _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 64,
                          onTap: _togglePlay,
                        ),
                        const SizedBox(width: 16),
                        _RoundIconButton(
                          icon: Icons.forward_10_rounded,
                          size: 40,
                          onTap: () => _seekRelative(_skipSeconds),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 4,
                    child: Row(
                      children: [
                        Text(
                          _ControlsOverlay._fmt(currentSecs.round()),
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.onDark),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: AppColors.blue,
                              inactiveTrackColor: AppColors.onDarkSubtle,
                              thumbColor: AppColors.blue,
                              overlayColor: AppColors.blueLightGlow10,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: currentSecs.clamp(0, maxSecs),
                              max: maxSecs,
                              onChangeStart: (v) {
                                _hideTimer?.cancel();
                                setState(() {
                                  _seeking = true;
                                  _seekValue = v;
                                });
                              },
                              onChanged: (v) =>
                                  setState(() => _seekValue = v),
                              onChangeEnd: (v) {
                                _ctrl.seekTo(
                                  seconds: v,
                                  allowSeekAhead: true,
                                );
                                setState(() {
                                  _seeking = false;
                                  _position =
                                      Duration(seconds: v.round());
                                });
                                _scheduleHide();
                              },
                            ),
                          ),
                        ),
                        Text(
                          _ControlsOverlay._fmt(_duration.inSeconds),
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.onDark),
                        ),
                        const SizedBox(width: 4),
                        _RoundIconButton(
                          icon: Icons.fullscreen_exit_rounded,
                          size: 24,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
