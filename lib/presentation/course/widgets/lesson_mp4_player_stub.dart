import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/utils/lesson_mp4_diagnostics.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import '../../../core/widgets/lesson_surface_gate.dart';
import 'lesson_video_chrome.dart';
import 'lesson_video_fullscreen.dart';

/// Progressive CDN MP4 for Prime Academy's Server (`videoMethods` = 0).
///
/// API / CDN facts (unchanged):
/// - `video_source.mime_type == video/mp4`
/// - Extensionless key: `uploads/lessons/<id>`
/// - No DRM (no pssh / encv). Byte-range progressive MP4.
///
/// Root cause of the false "تعذّر فك تشفير الفيديو" message:
/// 1. Path has no `.mp4` → AVPlayer / naive demuxers fail format sniffing.
/// 2. Some lessons have a large `moov` atom (>5MB). Default lavf probesize
///    (~5MB) cannot finish probing → open/demux error.
/// 3. That error was mis-mapped to a "decrypt/decode" user string.
///
/// Fix: libmpv via media_kit with `demuxer-lavf-format=mp4` and a probesize
/// large enough for lesson `moov` atoms. URL is passed unchanged. No DRM.
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

  /// Larger than the biggest observed lesson `moov` (~5.4MB) with headroom.
  static const _lavfProbesizeBytes = 32 * 1024 * 1024;

  Player? _player;
  VideoController? _videoController;
  late final LessonPlaybackTracker _tracker;
  late final StallWatch _stall;
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
  var _hasResumed = false;
  var _fullscreenOpen = false;
  var _loading = false;
  String? _error;
  double _seekValue = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  LessonMp4ProbeResult? _lastProbe;

  @override
  void initState() {
    super.initState();
    LessonSurfaceGate.instance.register(_releaseLessonSurface);
    LessonSurfaceGate.instance.addListener(_onSurfaceGateChanged);
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    _stall = StallWatch(thresholdSeconds: 120, onStall: _reload)..start();
    unawaited(_tracker.resolve());
    debugPrint(
      '[LessonMp4] mount url=${LessonMp4Diagnostics.playbackUrl(widget.videoUrl)} '
      'apiMime=${VideoSource.normalizeMime(widget.mimeType)} '
      'format=${VideoSource.detectFormatLabel(widget.videoUrl, widget.mimeType)} '
      'drm=none player=media_kit/libmpv',
    );
  }

  void _onSurfaceGateChanged() {
    if (!LessonSurfaceGate.instance.suppressed || !mounted) return;
    unawaited(_releaseLessonSurface());
  }

  Future<void> _releaseLessonSurface() async {
    if (_player == null && !_ready) return;
    if (kDebugMode) {
      debugPrint('[LessonSurface] MP4/media_kit release');
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
  void didUpdateWidget(covariant LessonMp4Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _hasEnded = false;
      _hasResumed = false;
      _started = false;
      _playing = false;
      _ready = false;
      unawaited(_disposePlayer());
      setState(() {
        _error = null;
        _loading = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
  }

  Future<void> _disposePlayer() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    final player = _player;
    _player = null;
    _videoController = null;
    _ready = false;
    if (player != null) {
      await player.dispose();
    }
  }

  Future<void> _configureDemuxerForExtensionlessMp4(Player player) async {
    final platform = player.platform;
    if (platform is! NativePlayer) {
      debugPrint('[LessonMp4] platform is not NativePlayer; skip lavf props');
      return;
    }

    // Force MP4 demuxer: CDN keys have no file extension. Browsers use
    // Content-Type / <source type="video/mp4">; libmpv needs an explicit format.
    await platform.setProperty('demuxer-lavf-format', 'mp4');
    await platform.setProperty(
      'demuxer-lavf-probesize',
      '$_lavfProbesizeBytes',
    );
    // Seconds — enough to ingest large moov before mdat on multi-GB lessons.
    await platform.setProperty('demuxer-lavf-analyzeduration', '120');
    debugPrint(
      '[LessonMp4] lavf format=mp4 probesize=$_lavfProbesizeBytes '
      'analyzeduration=120s',
    );
  }

  void _listen(Player player) {
    _subscriptions.addAll([
      player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() {
          _playing = playing;
          // Playback succeeded — clear any transient open/probe overlay.
          if (playing) {
            _error = null;
            _buffering = false;
            _tracker.onPlay();
            _scheduleHide();
          } else {
            _tracker.onPause();
            _hideTimer?.cancel();
            _controlsVisible = true;
          }
        });
        _stall.setPlaying(playing);
      }),
      player.stream.buffering.listen((buffering) {
        if (!mounted) return;
        setState(() => _buffering = buffering);
      }),
      player.stream.completed.listen((completed) {
        if (!completed || !mounted || _hasEnded) return;
        _hasEnded = true;
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
        setState(() {
          _playing = false;
          _controlsVisible = true;
        });
      }),
      player.stream.duration.listen((duration) {
        if (!mounted) return;
        setState(() {
          _duration = duration;
          if (duration > Duration.zero) _error = null;
        });
      }),
      player.stream.position.listen((position) {
        if (!mounted) return;
        _position = position;
        final total = _duration;
        if (total > Duration.zero) {
          final seconds = position.inSeconds;
          final totalSec = total.inSeconds;
          if (totalSec > 0) {
            final pct = ((seconds / totalSec) * 100).clamp(0, 100).round();
            widget.onProgressUpdate?.call(pct);
            _tracker.update(seconds: seconds, duration: totalSec);
            _stall.reportTime(seconds.toDouble());
          }
        }
        // Advancing position means the stream is healthy.
        if (_error != null && position > Duration.zero) {
          setState(() => _error = null);
        } else {
          setState(() {});
        }
      }),
      player.stream.log.listen((log) {
        debugPrint('[LessonMp4][mpv] ${log.level}: ${log.text}');
      }),
      player.stream.error.listen((message) {
        debugPrint('[LessonMp4][mpv][error] $message');
        if (!mounted || message.isEmpty) return;

        // libmpv often emits soft/transient errors while probing large moov /
        // HTTP ranges; playback can still succeed. Never cover a live player.
        final state = player.state;
        if (_ready ||
            state.playing ||
            state.position > Duration.zero ||
            state.duration > Duration.zero) {
          debugPrint(
            '[LessonMp4] ignoring non-fatal mpv error while playback healthy',
          );
          return;
        }
        if (_isBenignMpvError(message)) {
          debugPrint('[LessonMp4] ignoring benign mpv error: $message');
          return;
        }

        final failure = LessonMp4Diagnostics.classifyFailure(
          message,
          probe: _lastProbe,
        );
        setState(() {
          _loading = false;
          _buffering = false;
          _error = failure.userMessage;
        });
      }),
    ]);
  }

  /// Soft mpv/ffmpeg messages that must not replace the player UI.
  static bool _isBenignMpvError(String message) {
    final lower = message.toLowerCase();
    const benign = [
      'will retry',
      'retrying',
      'ffurl_read',
      'http error 416',
      'server returned 4xx',
      'end of file',
      'eof',
      'seeking is disabled',
    ];
    for (final token in benign) {
      if (lower.contains(token)) return true;
    }
    return false;
  }

  Future<void> _ensureInitialized({required bool autoPlay}) async {
    if (_initializing) return;
    if (_ready && _player != null) {
      if (autoPlay) await _player!.play();
      return;
    }

    final generation = ++_generation;
    _initializing = true;
    setState(() {
      _loading = true;
      _buffering = true;
      _error = null;
      _started = true;
      _controlsVisible = true;
    });

    await _disposePlayer();

    final url = LessonMp4Diagnostics.playbackUrl(widget.videoUrl);
    debugPrint('[LessonMp4] open unchanged url=$url headers=none');

    _lastProbe = await LessonMp4Diagnostics.probe(url);
    if (!mounted || generation != _generation) {
      _initializing = false;
      return;
    }

    if (_lastProbe!.statusCode > 0 && _lastProbe!.statusCode >= 400) {
      final failure = LessonMp4Diagnostics.classifyFailure(
        'HTTP ${_lastProbe!.statusCode}',
        probe: _lastProbe,
      );
      setState(() {
        _loading = false;
        _buffering = false;
        _error = failure.userMessage;
      });
      _initializing = false;
      return;
    }

    final player = Player(
      configuration: PlayerConfiguration(
        title: 'Prime Academy Lesson',
        bufferSize: 64 * 1024 * 1024,
        logLevel: kDebugMode ? MPVLogLevel.warn : MPVLogLevel.error,
      ),
    );
    final videoController = VideoController(player);
    _player = player;
    _videoController = videoController;
    _listen(player);

    try {
      await _configureDemuxerForExtensionlessMp4(player);

      // No custom headers: CDN serves the same bytes without Referer/Auth.
      // Browsers add Referer automatically; native progressive GET does not
      // need it (verified: HEAD/GET 200/206 with Content-Type video/mp4).
      await player.open(
        Media(url),
        play: false,
      );

      if (!mounted || generation != _generation) return;

      await _applyResume(player);
      await player.setVolume(_muted ? 0 : 100);
      await player.setRate(_rate);

      if (!mounted || generation != _generation) return;
      setState(() {
        _ready = true;
        _loading = false;
        _buffering = false;
        _error = null;
        _duration = player.state.duration;
      });

      debugPrint(
        '[LessonMp4] opened ok duration=${player.state.duration} '
        'width=${player.state.width} height=${player.state.height}',
      );

      if (autoPlay) {
        await player.play();
      }
    } catch (error, stack) {
      final failure = LessonMp4Diagnostics.classifyFailure(
        error,
        stackTrace: stack,
        probe: _lastProbe,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _ready = false;
        _loading = false;
        _buffering = false;
        _playing = false;
        _error = failure.userMessage;
      });
      await _disposePlayer();
    } finally {
      _initializing = false;
    }
  }

  Future<void> _applyResume(Player player) async {
    if (_hasResumed) return;
    final resume = VideoProgress.resumePositionSeconds(
      widget.initialPositionSeconds,
    );
    if (resume <= 0) {
      _hasResumed = true;
      return;
    }
    final duration = player.state.duration;
    var pos = resume;
    if (duration > Duration.zero && pos >= duration.inSeconds - 5) {
      pos = (duration.inSeconds - 5).clamp(0, duration.inSeconds);
    }
    if (pos > 0) {
      await player.seek(Duration(seconds: pos));
    }
    _hasResumed = true;
  }

  void _reload() {
    _hasEnded = false;
    _hasResumed = false;
    _started = false;
    _playing = false;
    _ready = false;
    unawaited(() async {
      await _disposePlayer();
      if (!mounted) return;
      setState(() {
        _error = null;
        _loading = false;
      });
      await _ensureInitialized(autoPlay: true);
    }());
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
    if (player != null) {
      unawaited(player.setVolume(_muted ? 0 : 100));
    }
    _showControls();
  }

  void _setRate(double rate) {
    setState(() => _rate = rate);
    final player = _player;
    if (player != null) {
      unawaited(player.setRate(rate));
    }
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
    if (kIsWeb) {
      if (isFullscreen) {
        await exitBrowserFullscreen();
      } else {
        await enterBrowserFullscreen();
      }
      if (mounted) setState(() {});
      return;
    }

    if (isFullscreen || _fullscreenOpen) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
    if (controller == null) {
      return const ColoredBox(color: Colors.black);
    }
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
      isFullscreen: isFullscreen || (kIsWeb && isBrowserFullscreen),
      muted: _muted,
      playbackRate: _rate,
      position: _seeking
          ? Duration(milliseconds: (_seekValue * 1000).round())
          : _position,
      duration: _duration,
      seeking: _seeking,
      seekValue: _seekValue,
      thumbnailUrl: _started ? null : widget.thumbnailUrl,
      errorMessage: _error,
      onRetry: () {
        _error = null;
        _reload();
      },
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
        final player = _player;
        if (player != null) {
          unawaited(
            player.seek(Duration(milliseconds: (v * 1000).round())),
          );
        }
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
    LessonSurfaceGate.instance.removeListener(_onSurfaceGateChanged);
    LessonSurfaceGate.instance.unregister(_releaseLessonSurface);
    _hideTimer?.cancel();
    _fullscreenUi.dispose();
    _stall.dispose();
    _tracker.dispose();
    unawaited(_disposePlayer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullscreen = kIsWeb && isBrowserFullscreen;
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
          _chrome(isFullscreen: isFullscreen),
        ],
      ),
    );
  }
}
