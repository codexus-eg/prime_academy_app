import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/utils/bunny_hls_manifest.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/widgets/lesson_surface_gate.dart';
import 'lesson_video_chrome.dart';
import 'lesson_video_fullscreen.dart';

/// Bunny Stream via HLS master playlist (qualities from the real manifest).
class LessonBunnyHlsPlayer extends StatefulWidget {
  const LessonBunnyHlsPlayer({
    super.key,
    required this.resolved,
    this.thumbnailUrl,
    this.lessonId,
    this.initialPositionSeconds = 0,
    this.onProgressUpdate,
    this.onWatched,
    this.onPlaybackEnded,
  });

  final BunnyHlsResolved resolved;
  final String? thumbnailUrl;
  final int? lessonId;
  final int initialPositionSeconds;
  final ValueChanged<int>? onProgressUpdate;
  final VoidCallback? onWatched;
  final VoidCallback? onPlaybackEnded;

  @override
  State<LessonBunnyHlsPlayer> createState() => _LessonBunnyHlsPlayerState();
}

class _LessonBunnyHlsPlayerState extends State<LessonBunnyHlsPlayer> {
  static const _autoHide = Duration(seconds: 3);
  static const _autoLabel = 'Auto';

  Player? _player;
  VideoController? _videoController;
  late final LessonPlaybackTracker _tracker;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  Timer? _hideTimer;
  /// Rebuilds the pushed fullscreen route when this State calls [setState].
  final _fullscreenUi = LessonFullscreenUiTick();
  var _generation = 0;
  var _initializing = false;
  var _ready = false;
  var _started = false;
  var _playing = false;
  var _buffering = false;
  var _controlsVisible = true;
  var _seeking = false;
  var _muted = false;
  var _rate = 1.0;
  var _hasEnded = false;
  var _loading = true;
  var _fullscreenOpen = false;
  String? _error;
  double _seekValue = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _qualityLabel = _autoLabel;

  List<String> get _qualities => [
        _autoLabel,
        ...widget.resolved.qualityLabels,
      ];

  @override
  void initState() {
    super.initState();
    LessonSurfaceGate.instance.register(_releaseLessonSurface);
    LessonSurfaceGate.instance.addListener(_onSurfaceGateChanged);
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    unawaited(_tracker.resolve());
    unawaited(_ensureInitialized(autoPlay: false));
  }

  void _onSurfaceGateChanged() {
    if (!LessonSurfaceGate.instance.suppressed || !mounted) return;
    unawaited(_releaseLessonSurface());
  }

  Future<void> _releaseLessonSurface() async {
    if (_player == null && !_ready) return;
    if (kDebugMode) {
      debugPrint('[LessonSurface] Bunny HLS release');
    }
    await _disposePlayer();
    if (mounted) {
      setState(() {
        _playing = false;
        _ready = false;
      });
    }
  }

  @override
  void dispose() {
    LessonSurfaceGate.instance.removeListener(_onSurfaceGateChanged);
    LessonSurfaceGate.instance.unregister(_releaseLessonSurface);
    _hideTimer?.cancel();
    _fullscreenUi.dispose();
    _tracker.dispose();
    unawaited(_disposePlayer());
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    final player = _player;
    _player = null;
    _videoController = null;
    await player?.dispose();
  }

  void _listen(Player player) {
    _subscriptions
      ..add(player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() {
          _playing = playing;
          if (playing) {
            _started = true;
            _buffering = false;
            _loading = false;
          }
        });
        if (playing) {
          _tracker.onPlay();
          _scheduleHide();
        } else {
          _tracker.onPause();
          _hideTimer?.cancel();
          setState(() => _controlsVisible = true);
        }
      }))
      ..add(player.stream.buffering.listen((buffering) {
        if (!mounted) return;
        setState(() => _buffering = buffering);
      }))
      ..add(player.stream.position.listen((position) {
        if (!mounted || _seeking) return;
        setState(() => _position = position);
        final duration = _duration.inSeconds;
        if (duration > 0) {
          final seconds = position.inSeconds;
          final pct = ((seconds / duration) * 100).clamp(0, 100).round();
          widget.onProgressUpdate?.call(pct);
          _tracker.update(seconds: seconds, duration: duration);
        }
      }))
      ..add(player.stream.duration.listen((duration) {
        if (!mounted || duration <= Duration.zero) return;
        setState(() => _duration = duration);
      }))
      ..add(player.stream.completed.listen((completed) {
        if (!completed || !mounted || _hasEnded) return;
        _hasEnded = true;
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
        setState(() {
          _playing = false;
          _controlsVisible = true;
        });
      }));
  }

  Future<void> _ensureInitialized({
    required bool autoPlay,
    String? mediaUrl,
  }) async {
    if (_initializing) return;
    if (_ready && _player != null && mediaUrl == null) {
      if (autoPlay) await _player!.play();
      return;
    }

    final generation = ++_generation;
    _initializing = true;
    final resumeAt = _position.inSeconds > 0
        ? _position.inSeconds
        : VideoProgress.resumePositionSeconds(widget.initialPositionSeconds);

    setState(() {
      _loading = true;
      _buffering = true;
      _error = null;
      _controlsVisible = true;
    });

    await _disposePlayer();

    final url = mediaUrl ?? widget.resolved.playlistUrl;
    final player = Player(
      configuration: PlayerConfiguration(
        title: 'Prime Academy Bunny',
        bufferSize: 64 * 1024 * 1024,
        logLevel: kDebugMode ? MPVLogLevel.warn : MPVLogLevel.error,
      ),
    );
    final videoController = VideoController(player);
    _player = player;
    _videoController = videoController;
    _listen(player);

    try {
      await player.open(
        Media(url, httpHeaders: BunnyHlsManifest.playbackHeaders),
        play: false,
      );
      if (!mounted || generation != _generation) return;

      if (resumeAt > 0) {
        final duration = player.state.duration.inSeconds;
        final safe = duration > 0
            ? VideoProgress.clampResumePosition(resumeAt, duration)
            : resumeAt;
        if (safe > 0) await player.seek(Duration(seconds: safe));
      }

      await player.setVolume(_muted ? 0 : 100);
      await player.setRate(_rate);

      if (!mounted || generation != _generation) return;
      setState(() {
        _ready = true;
        _loading = false;
        _buffering = false;
        _duration = player.state.duration;
        _position = player.state.position;
      });

      if (autoPlay) {
        setState(() => _started = true);
        await player.play();
      }
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _ready = false;
        _loading = false;
        _buffering = false;
        // Real failure only — never treat init race as "unavailable".
        _error = 'تعذّر تشغيل الفيديو. تحقّق من الاتصال أو أعد المحاولة.';
      });
      debugPrint('[BunnyHls] open failed: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _setQuality(String label) async {
    if (label == _qualityLabel) return;
    final wasPlaying = _playing || _started;
    final pos = _position;

    setState(() => _qualityLabel = label);

    String? url;
    if (label == _autoLabel) {
      url = widget.resolved.playlistUrl;
    } else {
      for (final variant in widget.resolved.variants) {
        if (variant.label == label) {
          url = variant.uri;
          break;
        }
      }
    }
    if (url == null) return;

    _ready = false;
    _position = pos;
    await _ensureInitialized(autoPlay: wasPlaying, mediaUrl: url);
    _showControls();
  }

  void _togglePlay() {
    final player = _player;
    if (_ready && player != null) {
      if (player.state.playing) {
        unawaited(player.pause());
      } else {
        _hasEnded = false;
        unawaited(player.play());
      }
      _showControls();
      return;
    }
    unawaited(_ensureInitialized(autoPlay: true));
    _showControls();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    final player = _player;
    if (player != null) unawaited(player.setVolume(_muted ? 0 : 100));
    _showControls();
  }

  void _setRate(double rate) {
    setState(() => _rate = rate);
    final player = _player;
    if (player != null) unawaited(player.setRate(rate));
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

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_fullscreenOpen) _fullscreenUi.bump();
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
    if (isFullscreen || _fullscreenOpen) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    if (!_ready) {
      await _ensureInitialized(autoPlay: false);
      if (!_ready || !mounted) return;
    }
    setState(() => _fullscreenOpen = true);
    _showControls();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ListenableBuilder(
          listenable: _fullscreenUi,
          builder: (context, _) => LessonVideoFullscreenPage(
            onClose: () {},
            child: LessonVideoPlayerShell(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _videoSurface(),
                  _chrome(isFullscreen: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _fullscreenOpen = false);
  }

  Widget _videoSurface() {
    final controller = _videoController;
    if (controller == null) return const ColoredBox(color: Colors.black);
    return Video(
      controller: controller,
      controls: NoVideoControls,
      fit: BoxFit.contain,
      fill: Colors.black,
    );
  }

  Widget _chrome({required bool isFullscreen}) {
    return LessonVideoChrome(
      started: _started,
      playing: _playing,
      buffering: _buffering || _initializing,
      loading: _loading && !_ready,
      controlsVisible: _controlsVisible,
      isFullscreen: isFullscreen,
      muted: _muted,
      playbackRate: _rate,
      position: _seeking
          ? Duration(milliseconds: (_seekValue * 1000).round())
          : _position,
      duration: _duration,
      seeking: _seeking,
      seekValue: _seekValue,
      thumbnailUrl: widget.thumbnailUrl,
      errorMessage: _error,
      onRetry: () {
        setState(() => _error = null);
        unawaited(_ensureInitialized(autoPlay: true));
      },
      qualityLabel: _qualityLabel,
      qualities: _qualities.length > 1 ? _qualities : const [],
      onQualityChanged: _qualities.length > 1 ? _setQuality : null,
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
        unawaited(_player?.seek(Duration(milliseconds: (v * 1000).round())));
        setState(() {
          _seeking = false;
          _position = Duration(milliseconds: (v * 1000).round());
          _hasEnded = false;
        });
        unawaited(_tracker.sync());
        _scheduleHide();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSurface = _ready &&
        !_fullscreenOpen &&
        !LessonSurfaceGate.instance.suppressed;
    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showSurface)
            _videoSurface()
          else
            const ColoredBox(color: Colors.black),
          if (!_fullscreenOpen) _chrome(isFullscreen: false),
        ],
      ),
    );
  }
}
