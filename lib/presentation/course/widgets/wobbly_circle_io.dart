import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

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
  static const _wobbleShaderAsset = 'shaders/wobbly_circle_wobble.frag';
  static const _perfectShaderAsset = 'shaders/wobbly_circle_perfect.frag';

  ui.FragmentProgram? _wobbleProgram;
  ui.FragmentProgram? _perfectProgram;
  bool _shaderFailed = false;

  late final Ticker _renderTicker;
  Duration _startTime = Duration.zero;
  final _shaderTick = _ShaderTickNotifier();

  int _scoreRef = 0;
  int _displayScore = 0;
  int _prevScore = 0;
  Ticker? _counterTicker;
  int _counterFrom = 0;
  int _counterTo = 0;

  bool get _isPerfect => !widget.staticWobble && widget.score >= 100;

  ui.FragmentProgram? get _activeProgram =>
      _isPerfect ? _perfectProgram : _wobbleProgram;

  bool get _useShader =>
      !_shaderFailed && _activeProgram != null;

  @override
  void initState() {
    super.initState();
    _scoreRef = widget.score;
    _displayScore = widget.score;
    _prevScore = widget.score;
    _loadShaders();
    _renderTicker = createTicker(_onRenderTick)..start();
  }

  Future<void> _loadShaders() async {
    try {
      final results = await Future.wait([
        ui.FragmentProgram.fromAsset(_wobbleShaderAsset),
        ui.FragmentProgram.fromAsset(_perfectShaderAsset),
      ]);
      if (!mounted) return;
      setState(() {
        _wobbleProgram = results[0];
        _perfectProgram = results[1];
      });
    } catch (error, stack) {
      debugPrint('WobblyCircle shader load failed, using CPU ring: $error\n$stack');
      if (!mounted) return;
      setState(() => _shaderFailed = true);
    }
  }

  void _onRenderTick(Duration elapsed) {
    if (_startTime == Duration.zero) {
      _startTime = elapsed;
    }
    _shaderTick.update(elapsed - _startTime);
  }

  @override
  void didUpdateWidget(covariant WobblyCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scoreRef = widget.score;
    if (oldWidget.score != widget.score) {
      _animateDisplayScore(_prevScore, widget.score);
    }
    final oldPerfect = !oldWidget.staticWobble && oldWidget.score >= 100;
    if (oldWidget.size != widget.size ||
        oldWidget.staticWobble != widget.staticWobble ||
        oldPerfect != _isPerfect) {
      _startTime = Duration.zero;
      _shaderTick.notify();
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
    _renderTicker.dispose();
    _counterTicker?.dispose();
    _shaderTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final bufferSize = size * dpr;
    final scoreFont = size * 0.19;
    final percentFont = size * 0.08;
    final labelFont = size * 0.055;
    final program = _activeProgram;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _useShader && program != null
                ? _HighDpiRingLayer(
                    logicalSize: size,
                    bufferSize: bufferSize,
                    child: CustomPaint(
                      size: Size(bufferSize, bufferSize),
                      painter: _WobblyCircleShaderPainter(
                        program: program,
                        tickNotifier: _shaderTick,
                        scoreReader: () => _scoreRef,
                        staticWobble: widget.staticWobble,
                        isPerfect: _isPerfect,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size(size, size),
                    painter: _WobblyRingPainter(
                      tickNotifier: _shaderTick,
                      score: _scoreRef,
                      staticWobble: widget.staticWobble,
                      isPerfect: _isPerfect,
                    ),
                  ),
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

class _HighDpiRingLayer extends StatelessWidget {
  const _HighDpiRingLayer({
    required this.logicalSize,
    required this.bufferSize,
    required this.child,
  });

  final double logicalSize;
  final double bufferSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: logicalSize,
      height: logicalSize,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: bufferSize,
          height: bufferSize,
          child: child,
        ),
      ),
    );
  }
}

class _ShaderTickNotifier extends ChangeNotifier {
  Duration value = Duration.zero;

  void update(Duration next) {
    value = next;
    notifyListeners();
  }

  void notify() => notifyListeners();
}

class _WobblyCircleShaderPainter extends CustomPainter {
  _WobblyCircleShaderPainter({
    required this.program,
    required _ShaderTickNotifier tickNotifier,
    required this.scoreReader,
    required this.staticWobble,
    required this.isPerfect,
  })  : _tickNotifier = tickNotifier,
        super(repaint: tickNotifier);

  final ui.FragmentProgram program;
  final _ShaderTickNotifier _tickNotifier;
  final int Function() scoreReader;
  final bool staticWobble;
  final bool isPerfect;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    final elapsed = _tickNotifier.value.inMicroseconds / 1000000.0;
    final currentScore = scoreReader().toDouble();

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, elapsed);

    if (!isPerfect) {
      final progress = staticWobble ? 0.0 : currentScore / 100.0;
      shader
        ..setFloat(3, progress)
        ..setFloat(4, 1.0)
        ..setFloat(5, currentScore);
    }

    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.srcOver
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.drawRect(Offset.zero & size, paint);
    shader.dispose();
  }

  @override
  bool shouldRepaint(covariant _WobblyCircleShaderPainter oldDelegate) {
    return oldDelegate.staticWobble != staticWobble ||
        oldDelegate.isPerfect != isPerfect ||
        oldDelegate.program != program;
  }
}

class _WobblyRingPainter extends CustomPainter {
  _WobblyRingPainter({
    required _ShaderTickNotifier tickNotifier,
    required this.score,
    required this.staticWobble,
    required this.isPerfect,
  })  : _tickNotifier = tickNotifier,
        super(repaint: tickNotifier);

  final _ShaderTickNotifier _tickNotifier;
  final int score;
  final bool staticWobble;
  final bool isPerfect;

  @override
  void paint(Canvas canvas, Size size) {
    final time = _tickNotifier.value.inMicroseconds / 1000000.0;
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    if (isPerfect) {
      _paintPerfectRing(canvas, center, side);
      return;
    }

    final progress = staticWobble ? 0.0 : score / 100.0;
    const maxNoiseStrength = 0.12;
    final noiseStrength = ui.lerpDouble(
          maxNoiseStrength,
          maxNoiseStrength * 0.1,
          progress,
        ) ??
        maxNoiseStrength;

    final colorT = _smoothstep(0.45, 0.55, score / 100.0);
    final edgeColor = Color.lerp(
      AppColors.wobblyRingGray,
      AppColors.wobblyRingBlue,
      colorT,
    )!;

    const baseRadius = 0.45;
    const edgeThickness = 0.20;
    final midRadius = baseRadius - edgeThickness / 2;

    final path = _wobblyPath(
      center: center,
      side: side,
      time: time,
      baseRadius: midRadius,
      noiseStrength: noiseStrength,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeThickness * side
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  void _paintPerfectRing(Canvas canvas, Offset center, double side) {
    const baseRadius = 0.45;
    const edgeThickness = 0.38;
    final midRadius = baseRadius - edgeThickness / 2;

    canvas.drawCircle(
      center,
      midRadius * side,
      Paint()
        ..color = AppColors.wobblyRingBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeThickness * side
        ..isAntiAlias = true,
    );
  }

  Path _wobblyPath({
    required Offset center,
    required double side,
    required double time,
    required double baseRadius,
    required double noiseStrength,
  }) {
    final path = Path();
    const segments = 240;
    for (var i = 0; i <= segments; i++) {
      final t = i / segments * math.pi * 2;
      final nx = math.cos(t) * 3.5 + time * 0.3;
      final ny = math.sin(t) * 3.5 + time * 0.3;
      final n = _noise(nx, ny);
      final bubbleRadius = baseRadius - noiseStrength * n;
      final r = bubbleRadius * side;
      final point = Offset(
        center.dx + math.cos(t) * r,
        center.dy + math.sin(t) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  double _fract(double v) => v - v.floorToDouble();

  double _hash(double x, double y) {
    var px = _fract(x * 5.3983);
    var py = _fract(y * 5.4427);
    final dot = px * (px + 3.5453123) + py * (py + 3.5453123);
    px += dot;
    py += dot;
    return _fract(px * py);
  }

  double _noise(double x, double y) {
    final iX = x.floorToDouble();
    final iY = y.floorToDouble();
    final fX = x - iX;
    final fY = y - iY;

    final a = _hash(iX, iY);
    final b = _hash(iX + 1, iY);
    final c = _hash(iX, iY + 1);
    final d = _hash(iX + 1, iY + 1);

    final uX = fX * fX * (3 - 2 * fX);
    final uY = fY * fY * (3 - 2 * fY);

    return a +
        (b - a) * uX +
        (c - a) * uY * (1 - uX) +
        (d - b) * uX * uY;
  }

  @override
  bool shouldRepaint(covariant _WobblyRingPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.staticWobble != staticWobble ||
        oldDelegate.isPerfect != isPerfect;
  }
}
