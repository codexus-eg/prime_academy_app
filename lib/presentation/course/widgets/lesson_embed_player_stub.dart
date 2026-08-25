import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import 'lesson_embed_support.dart';
import 'lesson_video_chrome.dart';

class LessonEmbedPlayer extends StatefulWidget {
  const LessonEmbedPlayer({
    super.key,
    required this.videoUrl,
    this.lessonId,
    this.initialPositionSeconds = 0,
    this.onProgressUpdate,
    this.onWatched,
    this.onPlaybackEnded,
  });

  final String videoUrl;
  final int? lessonId;
  final int initialPositionSeconds;
  final ValueChanged<int>? onProgressUpdate;
  final VoidCallback? onWatched;
  final VoidCallback? onPlaybackEnded;

  @override
  State<LessonEmbedPlayer> createState() => _LessonEmbedPlayerState();
}

class _LessonEmbedPlayerState extends State<LessonEmbedPlayer> {
  WebViewController? _controller;
  late final LessonPlaybackTracker _tracker;

  var _unsupported = false;
  var _isLoading = true;
  var _hasEnded = false;
  var _hasError = false;
  String? _missingId;

  bool get _showLoader =>
      _isLoading && defaultTargetPlatform != TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    unawaited(_tracker.resolve());
    unawaited(_createController(widget.videoUrl));
  }

  @override
  void didUpdateWidget(covariant LessonEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _hasEnded = false;
      _hasError = false;
      unawaited(_createController(widget.videoUrl));
    }
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
    });

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted) setState(() => _hasError = true);
          },
        ),
      );

    await controller.addJavaScriptChannel(
      'BunnyBridge',
      onMessageReceived: (message) => _onBridge(message.message),
    );

    final resume = VideoProgress.resumePositionSeconds(
      widget.initialPositionSeconds,
    );
    await controller.loadHtmlString(
      LessonEmbedSupport.wrapperHtml(
        videoUrl: url,
        resumeSeconds: resume,
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
          _hasError = false;
        });
      case 'timeupdate':
      case 'seeked':
        final seconds = (data['seconds'] as num?)?.toDouble() ?? 0;
        final duration = (data['duration'] as num?)?.toDouble() ?? 0;
        if (seconds <= 0 || duration <= 0) return;
        final pct = ((seconds / duration) * 100).clamp(0, 100).round();
        widget.onProgressUpdate?.call(pct);
        _tracker.update(seconds: seconds.round(), duration: duration.round());
        if (event == 'seeked') unawaited(_tracker.sync());
      case 'play':
        _tracker.onPlay();
      case 'pause':
        _tracker.onPause();
      case 'ended':
        if (!_hasEnded) {
          _hasEnded = true;
          unawaited(_tracker.sync());
          widget.onPlaybackEnded?.call();
        }
      case 'error':
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  void _retry() {
    _hasEnded = false;
    unawaited(_createController(widget.videoUrl));
  }

  @override
  void dispose() {
    _tracker.dispose();
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

    final controller = _controller;
    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_unsupported || controller == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'تعذّر تشغيل الفيديو داخل التطبيق على هذا الجهاز.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.onDark),
                ),
              ),
            )
          else
            WebViewWidget(controller: controller),
          if (_showLoader)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          if (_hasError)
            ColoredBox(
              color: const Color(0xCC000000),
              child: Center(
                child: TextButton(
                  onPressed: _retry,
                  child: const Text(
                    'تعذّر تشغيل الفيديو. إعادة المحاولة',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
