import 'dart:async';
import 'dart:js_interop';

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_radius.dart';
import 'lesson_video_fullscreen.dart';

class LessonEmbedPlayer extends StatefulWidget {
  const LessonEmbedPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<LessonEmbedPlayer> createState() => _LessonEmbedPlayerState();
}

class _LessonEmbedPlayerState extends State<LessonEmbedPlayer> {
  late final String _viewType;
  web.HTMLIFrameElement? _iframe;
  var _isFullscreen = false;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewType = 'lesson-embed-${identityHashCode(this)}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final iframe = web.HTMLIFrameElement()
        ..src = _embedSrc(widget.videoUrl)
        ..allowFullscreen = true
        ..setAttribute(
          'allow',
          'accelerometer; gyroscope; encrypted-media; picture-in-picture; fullscreen',
        );

      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..borderRadius = '${AppRadius.tailwindXl}px'
        ..display = 'block'
        ..backgroundColor = '#000';

      _iframe = iframe;

      iframe.addEventListener(
        'load',
        ((web.Event _) {
          if (mounted) setState(() => _isLoading = false);
        }).toJS,
      );
      iframe.addEventListener(
        'fullscreenchange',
        ((web.Event _) => _syncFullscreenState()).toJS,
      );

      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant LessonEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      final iframe = _iframe;
      if (iframe != null) {
        setState(() => _isLoading = true);
        iframe.src = _embedSrc(widget.videoUrl);
      }
    }
  }

  static String _embedSrc(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final params = Map<String, String>.from(uri.queryParameters)
      ..['autoplay'] = 'false';
    return uri.replace(queryParameters: params).toString();
  }

  void _syncFullscreenState() {
    final iframe = _iframe;
    if (iframe == null || !mounted) return;
    final active = isElementFullscreen(iframe);
    if (active != _isFullscreen) {
      setState(() => _isFullscreen = active);
    }
  }

  Future<void> _toggleFullscreen() async {
    final iframe = _iframe;
    if (iframe == null) return;

    if (_isFullscreen) {
      await exitBrowserFullscreen();
      return;
    }

    await requestWebElementFullscreen(iframe);
    _syncFullscreenState();
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
            if (_isLoading)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white70,
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
