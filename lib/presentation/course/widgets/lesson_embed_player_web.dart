import 'dart:async';
import 'dart:js_interop';

import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/bunny_hls_manifest.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import 'lesson_bunny_hls_player.dart';
import 'lesson_embed_support.dart';
import 'lesson_video_chrome.dart';
import 'lesson_video_fullscreen.dart';

@JS('playerjs')
external JSObject? get _playerJsNamespace;

@JS('playerjs.Player')
extension type _PlayerJsPlayer._(JSObject _) implements JSObject {
  external factory _PlayerJsPlayer(web.HTMLIFrameElement iframe);
  external void on(String event, JSFunction callback);
  external void setCurrentTime(num seconds);
  external void getDuration(JSFunction callback);
  external void getCurrentTime(JSFunction callback);
  external void play();
  external void pause();
  external void mute();
  external void unmute();
  external void setVolume(num volume);
  external void setPlaybackRate(num rate);
  external bool supports(String kind, String name);
}

extension type _PlayerJsTime._(JSObject _) implements JSObject {
  external num get seconds;
  external num get duration;
}

class LessonEmbedPlayer extends StatefulWidget {
  const LessonEmbedPlayer({
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
  State<LessonEmbedPlayer> createState() => _LessonEmbedPlayerState();
}

class _LessonEmbedPlayerState extends State<LessonEmbedPlayer> {
  static const _autoHide = Duration(seconds: 3);
  static const _maxRecoveryAttempts = 3;

  late final String _viewType;
  late final LessonPlaybackTracker _tracker;
  web.HTMLIFrameElement? _iframe;
  _PlayerJsPlayer? _player;
  Timer? _hideTimer;

  var _isLoading = true;
  var _hasEnded = false;
  var _hasError = false;
  var _hasStartedPlayback = false;
  var _lastPositionSeconds = 0;
  var _resumeSeconds = 0;
  var _recoveryAttempts = 0;
  var _missingId = false;
  BunnyHlsResolved? _hls;
  var _resolvingHls = true;

  var _started = false;
  var _playing = false;
  var _buffering = false;
  var _playerReady = false;
  var _pendingPlay = false;
  var _controlsVisible = true;
  var _seeking = false;
  var _muted = false;
  var _rate = 1.0;
  double _seekValue = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _viewType = 'lesson-embed-${identityHashCode(this)}';
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    _resumeSeconds = VideoProgress.resumePositionSeconds(
      widget.initialPositionSeconds,
    );
    unawaited(_tracker.resolve());
    _missingId = VideoSource.extractBunnyVideoId(widget.videoUrl) == null;
    if (_missingId) {
      _isLoading = false;
      _resolvingHls = false;
      return;
    }

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _resolvingHls = true;
      _isLoading = true;
      _hls = null;
    });
    final resolved = await BunnyHlsManifest.resolve(widget.videoUrl);
    if (!mounted) return;
    if (resolved != null) {
      setState(() {
        _hls = resolved;
        _resolvingHls = false;
        _isLoading = false;
      });
      return;
    }
    setState(() => _resolvingHls = false);
    _registerIframeFactory();
  }

  void _registerIframeFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final iframe = web.HTMLIFrameElement()
        ..src = VideoSource.withAutoplayDisabled(widget.videoUrl)
        ..allowFullscreen = true
        ..setAttribute('allow', LessonEmbedSupport.allow);

      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..borderRadius = '${AppRadius.tailwindXl}px'
        ..display = 'block'
        ..backgroundColor = '#000'
        ..pointerEvents = 'none';

      _iframe = iframe;
      _attachPlayerWhenReady(iframe);
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant LessonEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl == widget.videoUrl) return;
    final iframe = _iframe;
    _resetForNewSource();
    _missingId = VideoSource.extractBunnyVideoId(widget.videoUrl) == null;
    if (_missingId) {
      setState(() => _isLoading = false);
      return;
    }
    if (iframe != null) {
      setState(() {
        _isLoading = true;
        _playerReady = false;
        _pendingPlay = false;
      });
      iframe.src = VideoSource.withAutoplayDisabled(widget.videoUrl);
      _attachPlayerWhenReady(iframe);
    }
  }

  void _resetForNewSource() {
    _hasEnded = false;
    _hasError = false;
    _hasStartedPlayback = false;
    _recoveryAttempts = 0;
    _lastPositionSeconds = 0;
    _started = false;
    _playing = false;
    _buffering = false;
    _playerReady = false;
    _pendingPlay = false;
    _controlsVisible = true;
    _seeking = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _resumeSeconds = VideoProgress.resumePositionSeconds(
      widget.initialPositionSeconds,
    );
  }

  void _attachPlayerWhenReady(web.HTMLIFrameElement iframe) {
    var started = false;
    void startOnce(web.Event _) {
      if (started) return;
      started = true;
      _loadPlayerJs(() => _bindPlayer(iframe));
    }

    iframe.addEventListener('load', startOnce.toJS);
    // Fallback when the iframe finished loading before the listener attached.
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || started) return;
      startOnce(web.Event('load'));
    });
  }

  void _loadPlayerJs(VoidCallback onReady) {
    if (_playerJsNamespace != null) {
      onReady();
      return;
    }
    final existing = web.document.getElementById('playerjs-script');
    if (existing != null) {
      existing.addEventListener('load', ((web.Event _) => onReady()).toJS);
      return;
    }
    final script = web.HTMLScriptElement()
      ..id = 'playerjs-script'
      ..src = LessonEmbedSupport.playerJsUrl;
    script.addEventListener('load', ((web.Event _) => onReady()).toJS);
    web.document.body?.append(script);
  }

  void _bindPlayer(web.HTMLIFrameElement iframe) {
    if (_playerJsNamespace == null) return;
    _player = null;
    _playerReady = false;
    final player = _PlayerJsPlayer(iframe);
    _player = player;

    player.on(
      'ready',
      (() {
        if (!mounted) return;
        _playerReady = true;
        setState(() {
          _isLoading = false;
          _hasError = false;
          _buffering = false;
        });
        _recoveryAttempts = 0;
        if (_pendingPlay) {
          _pendingPlay = false;
          unawaited(_playWithGestureFallback());
        }
        player.getDuration(
          ((JSAny? raw) {
            if (raw == null) return;
            final duration = (raw as JSNumber).toDartDouble.round();
            final resume = _resumeSeconds > 0
                ? _resumeSeconds
                : VideoProgress.resumePositionSeconds(
                    widget.initialPositionSeconds,
                  );
            final safe = VideoProgress.clampResumePosition(resume, duration);
            if (safe > 0) player.setCurrentTime(safe);
          }).toJS,
        );
      }).toJS,
    );

    player.on(
      'timeupdate',
      ((JSAny? raw) {
        _onTime(raw, sync: false);
      }).toJS,
    );
    player.on(
      'play',
      (() {
        _tracker.onPlay();
        if (!mounted) return;
        setState(() {
          _started = true;
          _playing = true;
          _buffering = false;
          _isLoading = false;
        });
        _hasStartedPlayback = true;
        _scheduleHide();
      }).toJS,
    );
    player.on(
      'pause',
      (() {
        _tracker.onPause();
        if (!mounted) return;
        _hideTimer?.cancel();
        setState(() {
          _playing = false;
          _controlsVisible = true;
        });
      }).toJS,
    );
    player.on(
      'seeked',
      (() {
        player.getDuration(
          ((JSAny? durRaw) {
            final duration = durRaw == null
                ? 0
                : (durRaw as JSNumber).toDartDouble;
            if (duration > 0) unawaited(_tracker.sync());
          }).toJS,
        );
      }).toJS,
    );
    player.on(
      'ended',
      (() {
        if (_hasEnded) return;
        _hasEnded = true;
        _hideTimer?.cancel();
        if (mounted) {
          setState(() {
            _playing = false;
            _controlsVisible = true;
          });
        }
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
      }).toJS,
    );
    player.on(
      'error',
      (() {
        if (!mounted) return;
        if (_hasStartedPlayback) {
          _recoverFromPlaybackError();
          return;
        }
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }).toJS,
    );
  }

  void _onTime(JSAny? raw, {required bool sync}) {
    if (raw == null || !mounted) return;
    final data = raw as _PlayerJsTime;
    final seconds = data.seconds.toDouble();
    final duration = data.duration.toDouble();
    if (seconds <= 0 || duration <= 0) return;
    _lastPositionSeconds = seconds.round();
    if (seconds > 1) {
      _hasStartedPlayback = true;
      _started = true;
    }
    if (!_seeking) {
      setState(() {
        _position = Duration(milliseconds: (seconds * 1000).round());
        _duration = Duration(milliseconds: (duration * 1000).round());
        _isLoading = false;
        _buffering = false;
      });
    }
    final pct = ((seconds / duration) * 100).clamp(0, 100).round();
    widget.onProgressUpdate?.call(pct);
    _tracker.update(seconds: seconds.round(), duration: duration.round());
    if (sync) unawaited(_tracker.sync());
  }

  Future<void> _playWithGestureFallback() async {
    final player = _player;
    if (player == null) return;
    final wantSound = !_muted;
    try {
      if (wantSound) player.mute();
      player.play();
      if (wantSound) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted || _muted) return;
        player.unmute();
      }
    } catch (_) {}
  }

  void _togglePlay() {
    if (_hasError) return;
    if (!_started) {
      setState(() {
        _started = true;
        _controlsVisible = true;
        _buffering = true;
      });
      if (_playerReady && _player != null) {
        unawaited(_playWithGestureFallback());
      } else {
        _pendingPlay = true;
      }
      return;
    }
    final player = _player;
    if (player == null) return;
    if (_playing) {
      player.pause();
    } else {
      unawaited(_playWithGestureFallback());
    }
    _showControls();
  }

  void _toggleMute() {
    final player = _player;
    if (player == null) return;
    setState(() => _muted = !_muted);
    try {
      if (_muted) {
        player.mute();
      } else {
        player.unmute();
      }
    } catch (_) {}
    _showControls();
  }

  void _setRate(double rate) {
    final player = _player;
    if (player == null) return;
    setState(() => _rate = rate);
    try {
      if (player.supports('method', 'setPlaybackRate')) {
        player.setPlaybackRate(rate);
      }
    } catch (_) {}
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
    if (isFullscreen) {
      await exitBrowserFullscreen();
      if (mounted) setState(() {});
      return;
    }
    await enterBrowserFullscreen();
    if (mounted) setState(() {});
  }

  void _recoverFromPlaybackError() {
    if (_recoveryAttempts >= _maxRecoveryAttempts) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    _recoveryAttempts += 1;
    _reloadAtPosition();
  }

  void _reloadAtPosition() {
    final iframe = _iframe;
    if (iframe == null) return;
    _resumeSeconds = _lastPositionSeconds > 0
        ? _lastPositionSeconds
        : VideoProgress.resumePositionSeconds(widget.initialPositionSeconds);
    setState(() {
      _isLoading = true;
      _hasError = false;
      _playerReady = false;
      _pendingPlay = false;
    });
    iframe.src = VideoSource.withAutoplayDisabled(widget.videoUrl);
    _attachPlayerWhenReady(iframe);
  }

  void _retry() {
    final iframe = _iframe;
    _resetForNewSource();
    if (iframe == null) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _playerReady = false;
      _pendingPlay = false;
    });
    iframe.src = VideoSource.withAutoplayDisabled(widget.videoUrl);
    _attachPlayerWhenReady(iframe);
  }

  String? get _errorMessage =>
      _hasError ? 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.' : null;

  Widget _chrome({required bool isFullscreen}) {
    return LessonVideoChrome(
      started: _started,
      playing: _playing,
      buffering: _buffering,
      loading: _isLoading,
      controlsVisible: _controlsVisible,
      isFullscreen: isFullscreen || isBrowserFullscreen,
      muted: _muted,
      playbackRate: _rate,
      position: _position,
      duration: _duration,
      seeking: _seeking,
      seekValue: _seekValue,
      thumbnailUrl: widget.thumbnailUrl,
      errorMessage: _errorMessage,
      onRetry: _retry,
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
        _player?.setCurrentTime(v);
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
    _player?.pause();
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_missingId) {
      return const LessonVideoPlayerShell(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'تعذّر تشغيل الفيديو داخل التطبيق على هذا الجهاز.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onDark),
            ),
          ),
        ),
      );
    }

    if (_resolvingHls) {
      return const LessonVideoPlayerShell(
        child: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.blue,
            ),
          ),
        ),
      );
    }

    final hls = _hls;
    if (hls != null) {
      return LessonBunnyHlsPlayer(
        key: ValueKey('bunny-hls-web-${widget.videoUrl}'),
        resolved: hls,
        thumbnailUrl: widget.thumbnailUrl,
        lessonId: widget.lessonId,
        initialPositionSeconds: widget.initialPositionSeconds,
        onProgressUpdate: widget.onProgressUpdate,
        onWatched: widget.onWatched,
        onPlaybackEnded: widget.onPlaybackEnded,
      );
    }

    final isFullscreen = isBrowserFullscreen;
    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView(viewType: _viewType),
          _chrome(isFullscreen: isFullscreen),
        ],
      ),
    );
  }
}
