import 'dart:async';
import 'dart:js_interop';

import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/lesson_playback_tracker.dart';
import '../../../core/utils/video_progress.dart';
import '../../../core/utils/video_source.dart';
import 'lesson_embed_support.dart';
import 'lesson_video_chrome.dart';

@JS('playerjs')
external JSObject? get _playerJsNamespace;

@JS('playerjs.Player')
extension type _PlayerJsPlayer._(JSObject _) implements JSObject {
  external factory _PlayerJsPlayer(web.HTMLIFrameElement iframe);
  external void on(String event, JSFunction callback);
  external void setCurrentTime(num seconds);
  external void getDuration(JSFunction callback);
  external void pause();
}

extension type _PlayerJsTime._(JSObject _) implements JSObject {
  external num get seconds;
  external num get duration;
}

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
  late final String _viewType;
  late final LessonPlaybackTracker _tracker;
  web.HTMLIFrameElement? _iframe;
  _PlayerJsPlayer? _player;

  var _isLoading = true;
  var _hasEnded = false;
  var _hasError = false;
  var _missingId = false;

  bool get _showLoader =>
      _isLoading && defaultTargetPlatform != TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _viewType = 'lesson-embed-${identityHashCode(this)}';
    _tracker = LessonPlaybackTracker(
      lessonId: widget.lessonId,
      onWatched: widget.onWatched,
    );
    unawaited(_tracker.resolve());
    _missingId = VideoSource.extractBunnyVideoId(widget.videoUrl) == null;
    if (_missingId) {
      _isLoading = false;
      return;
    }

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
        ..backgroundColor = '#000';

      _iframe = iframe;
      _loadPlayerJs(() => _bindPlayer(iframe));
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant LessonEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl == widget.videoUrl) return;
    final iframe = _iframe;
    _hasEnded = false;
    _hasError = false;
    _missingId = VideoSource.extractBunnyVideoId(widget.videoUrl) == null;
    if (_missingId) {
      setState(() => _isLoading = false);
      return;
    }
    if (iframe != null) {
      setState(() => _isLoading = true);
      iframe.src = VideoSource.withAutoplayDisabled(widget.videoUrl);
      _loadPlayerJs(() => _bindPlayer(iframe));
    }
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
    final player = _PlayerJsPlayer(iframe);
    _player = player;

    player.on(
      'ready',
      (() {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        player.getDuration(
          ((JSAny? raw) {
            if (raw == null) return;
            final duration = (raw as JSNumber).toDartDouble.round();
            final resume = VideoProgress.resumePositionSeconds(
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
    player.on('play', (() => _tracker.onPlay()).toJS);
    player.on('pause', (() => _tracker.onPause()).toJS);
    player.on(
      'seeked',
      (() {
        player.getDuration(
          ((JSAny? durRaw) {
            final duration = durRaw == null
                ? 0
                : (durRaw as JSNumber).toDartDouble;
            // PlayerJS seeked has no payload; timeupdate will follow.
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
        unawaited(_tracker.sync());
        widget.onPlaybackEnded?.call();
      }).toJS,
    );
    player.on(
      'error',
      (() {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }).toJS,
    );
  }

  void _onTime(JSAny? raw, {required bool sync}) {
    if (raw == null || !mounted) return;
    final data = raw as _PlayerJsTime;
    final seconds = data.seconds.toDouble();
    final duration = data.duration.toDouble();
    if (seconds <= 0 || duration <= 0) return;
    final pct = ((seconds / duration) * 100).clamp(0, 100).round();
    widget.onProgressUpdate?.call(pct);
    _tracker.update(seconds: seconds.round(), duration: duration.round());
    if (sync) unawaited(_tracker.sync());
  }

  void _retry() {
    final iframe = _iframe;
    _hasEnded = false;
    if (iframe == null) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    iframe.src = VideoSource.withAutoplayDisabled(widget.videoUrl);
    _loadPlayerJs(() => _bindPlayer(iframe));
  }

  @override
  void dispose() {
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

    return LessonVideoPlayerShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView(viewType: _viewType),
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
