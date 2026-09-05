import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bunny_hls_manifest.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import '../../../core/widgets/lesson_surface_gate.dart';
import '../../../core/widgets/platform_view_occlusion.dart';
import 'lesson_bunny_hls_player.dart';
import 'lesson_embed_commands.dart';
import 'lesson_embed_support.dart';
import 'lesson_video_chrome.dart';
import 'lesson_video_fullscreen.dart';

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

  WebViewController? _controller;
  late final LessonPlaybackTracker _tracker;
  late final StallWatch _stall;
  Timer? _hideTimer;

  var _unsupported = false;
  var _isLoading = true;
  var _hasEnded = false;
  var _hasError = false;
  var _drawerOccluded = false;
  var _hasStartedPlayback = false;
  var _recovering = false;
  var _recoveryAttempts = 0;
  var _lastPositionSeconds = 0;
  var _resumeSeconds = 0;
  String? _missingId;
  /// When non-null, play via HLS (manifest qualities) instead of the iframe.
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
    LessonSurfaceGate.instance.register(_releaseLessonSurface);
    LessonSurfaceGate.instance.addListener(_onSurfaceGateChanged);
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    _resumeSeconds = VideoProgress.resumePositionSeconds(
      widget.initialPositionSeconds,
    );
    _stall = StallWatch(
      thresholdSeconds: 30,
      onStall: _reloadAtPosition,
    )..start();
    unawaited(_tracker.resolve());
    unawaited(_bootstrap());
  }

  void _onSurfaceGateChanged() {
    if (!LessonSurfaceGate.instance.suppressed || !mounted) return;
    unawaited(_releaseLessonSurface());
  }

  Future<void> _releaseLessonSurface() async {
    if (kDebugMode) {
      debugPrint('[LessonSurface] Embed/WebView release');
    }
    await _pauseEmbed();
    final controller = _controller;
    _controller = null;
    _playerReady = false;
    _playing = false;
    if (controller != null) {
      try {
        await controller.loadRequest(Uri.parse('about:blank'));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    setState(() {
      _resolvingHls = true;
      _isLoading = true;
      _hasError = false;
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
    await _createController(widget.videoUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final occluded = PlatformViewOcclusion.isOccluded(context);
    if (occluded == _drawerOccluded) return;
    _drawerOccluded = occluded;
    if (occluded) {
      unawaited(_pauseEmbed());
    }
  }

  Future<void> _runJs(String script) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript(script);
    } catch (_) {}
  }

  Future<void> _pauseEmbed() async {
    await _runJs(LessonEmbedCommands.pause());
  }

  @override
  void didUpdateWidget(covariant LessonEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _resetForNewSource();
      unawaited(_bootstrap());
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

  bool get _webviewSupported {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  PlatformWebViewControllerCreationParams _platformParams() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidWebViewControllerCreationParams();
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const {},
        );
      default:
        return const PlatformWebViewControllerCreationParams();
    }
  }

  Future<void> _configurePlatform(WebViewController controller) async {
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  bool _isFatalWebResourceError(WebResourceError error) {
    if (_hasStartedPlayback) {
      return error.errorType == WebResourceErrorType.webContentProcessTerminated;
    }
    return error.isForMainFrame != false;
  }

  Future<void> _createController(String url) async {
    final videoId = VideoSource.extractBunnyVideoId(url);
    if (videoId == null) {
      setState(() {
        _missingId = url;
        _controller = null;
        _isLoading = false;
      });
      return;
    }

    if (!_webviewSupported) {
      setState(() {
        _unsupported = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _missingId = null;
      _isLoading = true;
      _hasError = false;
      _recovering = false;
      _playerReady = false;
      _pendingPlay = false;
    });

    final controller = WebViewController.fromPlatformCreationParams(
      _platformParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (!mounted) return;
            debugPrint(
              '[LessonEmbed] webResourceError '
              'mainFrame=${error.isForMainFrame} '
              'type=${error.errorType} '
              'url=${error.url}',
            );
            if (!_isFatalWebResourceError(error)) return;
            if (_hasStartedPlayback) {
              _recoverFromPlaybackError('webResourceError');
              return;
            }
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      );

    await _configurePlatform(controller);

    await controller.addJavaScriptChannel(
      'BunnyBridge',
      onMessageReceived: (message) => _onBridge(message.message),
    );

    await controller.loadHtmlString(
      LessonEmbedSupport.wrapperHtml(
        videoUrl: url,
        resumeSeconds: _resumeSeconds,
      ),
      baseUrl: 'https://iframe.mediadelivery.net/',
    );

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _onBridge(String raw) {
    final data = LessonEmbedSupport.parseMessage(raw);
    if (data == null || !mounted) return;
    final event = data['event'] as String?;

    switch (event) {
      case 'ready':
        _playerReady = true;
        setState(() {
          _isLoading = false;
          _hasError = false;
          _recovering = false;
          _buffering = false;
        });
        _recoveryAttempts = 0;
        _stall.reset();
        if (_pendingPlay) {
          _pendingPlay = false;
          unawaited(_playWithGestureFallback());
        }
      case 'timeupdate':
      case 'seeked':
        final seconds = (data['seconds'] as num?)?.toDouble() ?? 0;
        final duration = (data['duration'] as num?)?.toDouble() ?? 0;
        if (seconds <= 0 || duration <= 0) return;
        _lastPositionSeconds = seconds.round();
        _stall.reportTime(seconds);
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
        if (event == 'seeked') unawaited(_tracker.sync());
      case 'play':
        _hasStartedPlayback = true;
        _stall.setPlaying(true);
        _tracker.onPlay();
        setState(() {
          _started = true;
          _playing = true;
          _buffering = false;
          _isLoading = false;
        });
        _scheduleHide();
      case 'pause':
        _stall.setPlaying(false);
        _tracker.onPause();
        _hideTimer?.cancel();
        setState(() {
          _playing = false;
          _controlsVisible = true;
        });
      case 'ended':
        _stall.setPlaying(false);
        _hideTimer?.cancel();
        setState(() {
          _playing = false;
          _controlsVisible = true;
        });
        if (!_hasEnded) {
          _hasEnded = true;
          unawaited(_tracker.sync());
          widget.onPlaybackEnded?.call();
        }
      case 'error':
        if (_hasStartedPlayback) {
          _recoverFromPlaybackError('playerjs');
          return;
        }
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  Future<void> _playWithGestureFallback() async {
    final wantSound = !_muted;
    if (wantSound) await _runJs(LessonEmbedCommands.mute());
    await _runJs(LessonEmbedCommands.play());
    if (wantSound) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || _muted) return;
      await _runJs(LessonEmbedCommands.unmute());
    }
  }

  void _togglePlay() {
    if (_drawerOccluded) return;
    if (_hasError) return;
    if (!_started) {
      setState(() {
        _started = true;
        _controlsVisible = true;
        _buffering = true;
      });
      if (_playerReady) {
        unawaited(_playWithGestureFallback());
      } else {
        _pendingPlay = true;
      }
      return;
    }
    if (_playing) {
      unawaited(_pauseEmbed());
    } else {
      unawaited(_playWithGestureFallback());
    }
    _showControls();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    unawaited(_runJs(
      _muted ? LessonEmbedCommands.mute() : LessonEmbedCommands.unmute(),
    ));
    _showControls();
  }

  void _setRate(double rate) {
    setState(() => _rate = rate);
    unawaited(_runJs(LessonEmbedCommands.setRate(rate)));
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
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    await _pauseEmbed();
    if (!mounted) return;
    final startPos = _position.inSeconds;
    var finalPos = startPos;
    var finalMuted = _muted;
    var finalRate = _rate;

    await openLessonVideoFullscreenRoute(
      context,
      builder: (ctx) => _BunnyFullscreenBody(
        videoUrl: widget.videoUrl,
        thumbnailUrl: widget.thumbnailUrl,
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
    setState(() {
      _muted = finalMuted;
      _rate = finalRate;
      _position = Duration(seconds: finalPos);
      _hasEnded = false;
    });
    unawaited(_runJs(
      _muted ? LessonEmbedCommands.mute() : LessonEmbedCommands.unmute(),
    ));
    unawaited(_runJs(LessonEmbedCommands.setRate(finalRate)));
    unawaited(_runJs(LessonEmbedCommands.seek(finalPos.toDouble())));
  }

  void _recoverFromPlaybackError(String source) {
    debugPrint(
      '[LessonEmbed] recoverFromPlaybackError source=$source '
      'position=$_lastPositionSeconds attempts=$_recoveryAttempts',
    );
    if (_recoveryAttempts >= _maxRecoveryAttempts) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    _reloadAtPosition();
  }

  void _reloadAtPosition() {
    if (_recovering) return;
    _recovering = true;
    _recoveryAttempts += 1;
    _resumeSeconds = _lastPositionSeconds > 0
        ? _lastPositionSeconds
        : VideoProgress.resumePositionSeconds(widget.initialPositionSeconds);
    _hasError = false;
    _isLoading = true;
    _stall.setPlaying(false);
    _stall.reset();
    unawaited(_createController(widget.videoUrl));
  }

  void _retry() {
    _resetForNewSource();
    unawaited(_bootstrap());
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
      isFullscreen: isFullscreen,
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
        unawaited(_runJs(LessonEmbedCommands.seek(v)));
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
    LessonSurfaceGate.instance.removeListener(_onSurfaceGateChanged);
    LessonSurfaceGate.instance.unregister(_releaseLessonSurface);
    _hideTimer?.cancel();
    _stall.dispose();
    _tracker.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_missingId != null) {
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
        key: ValueKey('bunny-hls-${widget.videoUrl}'),
        resolved: hls,
        thumbnailUrl: widget.thumbnailUrl,
        lessonId: widget.lessonId,
        initialPositionSeconds: widget.initialPositionSeconds,
        onProgressUpdate: widget.onProgressUpdate,
        onWatched: widget.onWatched,
        onPlaybackEnded: widget.onPlaybackEnded,
      );
    }

    final controller = _controller;
    final occluded = PlatformViewOcclusion.isOccluded(context) ||
        LessonSurfaceGate.instance.suppressed;
    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_unsupported || controller == null || occluded)
            const ColoredBox(color: Colors.black)
          else
            WebViewWidget(controller: controller),
          if (!occluded && controller != null) _chrome(isFullscreen: false),
        ],
      ),
    );
  }
}

class _BunnyFullscreenBody extends StatefulWidget {
  const _BunnyFullscreenBody({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.startSeconds,
    required this.muted,
    required this.rate,
    required this.onCloseState,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final int startSeconds;
  final bool muted;
  final double rate;
  final void Function(int position, bool muted, double rate) onCloseState;

  @override
  State<_BunnyFullscreenBody> createState() => _BunnyFullscreenBodyState();
}

class _BunnyFullscreenBodyState extends State<_BunnyFullscreenBody> {
  static const _autoHide = Duration(seconds: 3);

  WebViewController? _controller;
  Timer? _hideTimer;

  var _isLoading = true;
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
    unawaited(_createController());
  }

  Future<void> _runJs(String script) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript(script);
    } catch (_) {}
  }

  Future<void> _createController() async {
    final params = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidWebViewControllerCreationParams(),
      TargetPlatform.iOS || TargetPlatform.macOS =>
        WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const {},
        ),
      _ => const PlatformWebViewControllerCreationParams(),
    };

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
    }

    await controller.addJavaScriptChannel(
      'BunnyBridge',
      onMessageReceived: (message) => _onBridge(message.message),
    );

    await controller.loadHtmlString(
      LessonEmbedSupport.wrapperHtml(
        videoUrl: widget.videoUrl,
        resumeSeconds: widget.startSeconds,
      ),
      baseUrl: 'https://iframe.mediadelivery.net/',
    );

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _onBridge(String raw) {
    final data = LessonEmbedSupport.parseMessage(raw);
    if (data == null || !mounted) return;
    final event = data['event'] as String?;

    switch (event) {
      case 'ready':
        setState(() {
          _isLoading = false;
          _buffering = false;
        });
        unawaited(_runJs(
          _muted ? LessonEmbedCommands.mute() : LessonEmbedCommands.unmute(),
        ));
        unawaited(_runJs(LessonEmbedCommands.setRate(_rate)));
        unawaited(_playWithGestureFallback());
      case 'timeupdate':
      case 'seeked':
        final seconds = (data['seconds'] as num?)?.toDouble() ?? 0;
        final duration = (data['duration'] as num?)?.toDouble() ?? 0;
        if (seconds <= 0 || duration <= 0) return;
        if (!_seeking) {
          setState(() {
            _position = Duration(milliseconds: (seconds * 1000).round());
            _duration = Duration(milliseconds: (duration * 1000).round());
            _isLoading = false;
            _buffering = false;
          });
        }
        _emit();
      case 'play':
        setState(() {
          _playing = true;
          _buffering = false;
          _isLoading = false;
        });
        _scheduleHide();
        _emit();
      case 'pause':
        _hideTimer?.cancel();
        setState(() {
          _playing = false;
          _controlsVisible = true;
        });
        _emit();
    }
  }

  void _emit() =>
      widget.onCloseState(_position.inSeconds, _muted, _rate);

  Future<void> _playWithGestureFallback() async {
    final wantSound = !_muted;
    if (wantSound) await _runJs(LessonEmbedCommands.mute());
    await _runJs(LessonEmbedCommands.play());
    if (wantSound) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || _muted) return;
      await _runJs(LessonEmbedCommands.unmute());
    }
  }

  void _togglePlay() {
    if (_playing) {
      unawaited(_runJs(LessonEmbedCommands.pause()));
    } else {
      unawaited(_playWithGestureFallback());
    }
    _showControls();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    unawaited(_runJs(
      _muted ? LessonEmbedCommands.mute() : LessonEmbedCommands.unmute(),
    ));
    _showControls();
    _emit();
  }

  void _setRate(double rate) {
    setState(() => _rate = rate);
    unawaited(_runJs(LessonEmbedCommands.setRate(rate)));
    _showControls();
    _emit();
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
    _emit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null)
          WebViewWidget(controller: controller)
        else
          const ColoredBox(color: Colors.black),
        LessonVideoChrome(
          started: _started,
          playing: _playing,
          buffering: _buffering,
          loading: _isLoading,
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
          onToggleControls: _toggleControls,
          onToggleMute: _toggleMute,
          onRateChanged: _setRate,
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
            unawaited(_runJs(LessonEmbedCommands.seek(v)));
            setState(() {
              _seeking = false;
              _position = Duration(seconds: v.round());
            });
            _emit();
            _scheduleHide();
          },
        ),
      ],
    );
  }
}
