import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_fonts.dart';

@JS('PrimeWobblyCircle.mount')
external void _mount(web.HTMLCanvasElement canvas, JSAny? options);

@JS('PrimeWobblyCircle.unmount')
external void _unmount(web.HTMLCanvasElement canvas);

@JS('PrimeWobblyCircle.updateScore')
external void _updateScore(web.HTMLCanvasElement canvas, JSNumber score);

@JS('PrimeWobblyCircle.remount')
external void _remount(web.HTMLCanvasElement canvas, JSAny? options);

class WobblyCircle extends StatefulWidget {
  const WobblyCircle({
    super.key,
    this.score = 10,
    this.label = '',
    this.size = 215,
    this.staticWobble = false,
  });

  final int score;
  final String label;
  final double size;
  final bool staticWobble;

  @override
  State<WobblyCircle> createState() => _WobblyCircleState();
}

class _WobblyCircleState extends State<WobblyCircle>
    with TickerProviderStateMixin {
  late final String _viewType;
  web.HTMLCanvasElement? _canvas;

  int _displayScore = 0;
  int _prevScore = 0;
  Ticker? _counterTicker;
  int _counterFrom = 0;
  int _counterTo = 0;

  bool get _isPerfect => !widget.staticWobble && widget.score >= 100;

  @override
  void initState() {
    super.initState();
    _displayScore = widget.score;
    _prevScore = widget.score;
    _viewType = 'wobbly-circle-${identityHashCode(this)}';
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final canvas = web.HTMLCanvasElement()
        ..style.display = 'block'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent';
      _canvas = canvas;
      _mountGl(canvas);
      return canvas;
    });
  }

  JSObject _glOptions() {
    return <String, JSAny?>{
      'size': widget.size.toJS,
      'score': widget.score.toJS,
      'staticWobble': widget.staticWobble.toJS,
      'isPerfect': _isPerfect.toJS,
    }.jsify() as JSObject;
  }

  void _mountGl(web.HTMLCanvasElement canvas) {
    _mount(canvas, _glOptions());
  }

  @override
  void didUpdateWidget(covariant WobblyCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final canvas = _canvas;
    if (canvas == null) return;

    if (oldWidget.score != widget.score) {
      _updateScore(canvas, widget.score.toJS);
      _animateDisplayScore(_prevScore, widget.score);
    }

    final oldPerfect = !oldWidget.staticWobble && oldWidget.score >= 100;
    if (oldWidget.size != widget.size ||
        oldWidget.staticWobble != widget.staticWobble ||
        oldPerfect != _isPerfect) {
      _remount(canvas, _glOptions());
    }
  }

  void _animateDisplayScore(int from, int to) {
    if (to <= from) {
      _prevScore = to;
      setState(() => _displayScore = to);
      return;
    }

    final startFrom = _displayScore;
    _counterTicker?.dispose();
    _counterFrom = startFrom;
    _counterTo = to;
    _counterTicker = createTicker(_onCounterTick)..start();
  }

  void _onCounterTick(Duration elapsed) {
    const durationMs = 1000.0;
    final elapsedMs = elapsed.inMicroseconds / 1000.0;
    final t = (elapsedMs / durationMs).clamp(0.0, 1.0);
    final eased = 1 - (1 - t) * (1 - t) * (1 - t);
    final current =
        (_counterFrom + (_counterTo - _counterFrom) * eased).round();
    setState(() => _displayScore = current);
    if (t >= 1) {
      _counterTicker?.dispose();
      _counterTicker = null;
      _prevScore = _counterTo;
      setState(() => _displayScore = _counterTo);
    }
  }

  @override
  void dispose() {
    _counterTicker?.dispose();
    final canvas = _canvas;
    if (canvas != null) {
      _unmount(canvas);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final scoreFont = size * 0.19;
    final percentFont = size * 0.08;
    final labelFont = size * 0.055;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: HtmlElementView(viewType: _viewType),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '%',
                          style: TextStyle(
                            fontSize: percentFont,
                            fontWeight: AppFonts.semibold,
                            color: const Color.fromRGBO(255, 255, 255, 0.85),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$_displayScore',
                          style: TextStyle(
                            fontSize: scoreFont,
                            fontWeight: AppFonts.extrabold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    if (widget.label.isNotEmpty) ...[
                      SizedBox(height: size * 0.02),
                      Text(
                        widget.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: labelFont,
                          color: const Color.fromRGBO(255, 255, 255, 0.6),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
