import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/exam_celebration.dart';

/// Canvas-confetti style bursts matching web `useCelebration.ts`.
class ExamConfettiOverlay extends StatefulWidget {
  const ExamConfettiOverlay({
    super.key,
    required this.trigger,
    this.clearToken = 0,
    this.onComplete,
  });

  final int trigger;

  /// When incremented, any in-flight particles are discarded immediately.
  final int clearToken;

  final VoidCallback? onComplete;

  @override
  State<ExamConfettiOverlay> createState() => _ExamConfettiOverlayState();
}

class _ExamConfettiOverlayState extends State<ExamConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFF26CCFF),
    Color(0xFFA25AFD),
    Color(0xFFFF5E7E),
    Color(0xFF88FF5A),
    Color(0xFFFCFF42),
    Color(0xFFFFA62D),
    Color(0xFFFF36FF),
  ];

  late AnimationController _controller;
  List<_ConfettiPiece> _pieces = const [];
  var _lastTrigger = 0;
  var _lastClearToken = 0;
  var _lastEffect = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ExamCelebration.confettiLifetime,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _pieces = const []);
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExamConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clearToken != _lastClearToken) {
      _lastClearToken = widget.clearToken;
      _hardClear();
    }
    if (widget.trigger != _lastTrigger && widget.trigger > 0) {
      _lastTrigger = widget.trigger;
      _launch();
    }
  }

  void _hardClear() {
    final wasPlaying = _pieces.isNotEmpty;
    _controller.stop();
    _controller.reset();
    if (_pieces.isNotEmpty && mounted) {
      setState(() => _pieces = const []);
    } else {
      _pieces = const [];
    }
    if (wasPlaying) widget.onComplete?.call();
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 768;

  void _launch() {
    final random = math.Random();
    final mobile = _isMobile;
    final scale = mobile ? 0.7 : 1.0;

    var index = random.nextInt(2);
    if (index == _lastEffect) index = 1 - index;
    _lastEffect = index;

    final pieces = <_ConfettiPiece>[];
    if (mobile) {
      if (index == 0) {
        // Web confettiEffectsMobile[0]
        _spawnBurst(
          pieces: pieces,
          random: random,
          originX: 0.5,
          originY: 0.7,
          angleDeg: 90,
          spreadDeg: 70,
          startVelocity: 45,
          decay: 0.92,
          count: math.max(1, (90 * scale).floor()),
        );
      } else {
        // Web confettiEffectsMobile[1]
        _spawnBurst(
          pieces: pieces,
          random: random,
          originX: 0.5,
          originY: 0.6,
          angleDeg: 90,
          spreadDeg: 100,
          startVelocity: 35,
          decay: 0.9,
          count: math.max(1, (70 * scale).floor()),
        );
      }
    } else if (index == 0) {
      // Web confettiEffectsDesktop[0] — staggered shoots
      const waves = [
        (ratio: 0.25, spread: 26.0, velocity: 55.0, scalar: 1.0, decay: 0.9),
        (ratio: 0.20, spread: 60.0, velocity: 45.0, scalar: 1.0, decay: 0.9),
        (ratio: 0.35, spread: 100.0, velocity: 45.0, scalar: 0.8, decay: 0.91),
        (ratio: 0.10, spread: 120.0, velocity: 25.0, scalar: 1.2, decay: 0.92),
        (ratio: 0.10, spread: 120.0, velocity: 45.0, scalar: 1.0, decay: 0.9),
      ];
      for (var w = 0; w < waves.length; w++) {
        final wave = waves[w];
        _spawnBurst(
          pieces: pieces,
          random: random,
          originX: 0.5,
          originY: 0.7,
          angleDeg: 90,
          spreadDeg: wave.spread,
          startVelocity: wave.velocity,
          decay: wave.decay,
          count: math.max(1, (200 * wave.ratio * scale).floor()),
          scalar: wave.scalar,
          startDelay: w * 0.04,
        );
      }
    } else {
      // Web confettiEffectsDesktop[1] — side cannons
      final count = math.max(1, (80 * scale).floor());
      _spawnBurst(
        pieces: pieces,
        random: random,
        originX: 0,
        originY: 0.6,
        angleDeg: 60,
        spreadDeg: 55,
        startVelocity: 45,
        decay: 0.9,
        count: count,
      );
      _spawnBurst(
        pieces: pieces,
        random: random,
        originX: 1,
        originY: 0.6,
        angleDeg: 120,
        spreadDeg: 55,
        startVelocity: 45,
        decay: 0.9,
        count: count,
      );
    }

    _pieces = pieces;
    _controller.forward(from: 0);
  }

  void _spawnBurst({
    required List<_ConfettiPiece> pieces,
    required math.Random random,
    required double originX,
    required double originY,
    required double angleDeg,
    required double spreadDeg,
    required double startVelocity,
    required double decay,
    required int count,
    double scalar = 1,
    double startDelay = 0,
  }) {
    final speedNorm = startVelocity / 95;
    for (var i = 0; i < count; i++) {
      final spreadRad = spreadDeg * math.pi / 180;
      final angleRad = angleDeg * math.pi / 180;
      final theta = angleRad + (random.nextDouble() - 0.5) * spreadRad;
      final speed = speedNorm * (0.8 + random.nextDouble() * 0.4);
      pieces.add(
        _ConfettiPiece(
          x: originX,
          y: originY,
          vx: math.cos(theta) * speed,
          vy: -math.sin(theta) * speed,
          size: (random.nextDouble() * 6 + 5) * scalar,
          color: _colors[random.nextInt(_colors.length)],
          rotation: random.nextDouble() * math.pi * 2,
          spin: (random.nextDouble() - 0.5) * 12,
          decay: decay,
          startDelay: startDelay,
          isCircle: random.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pieces.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ConfettiPainter(
                pieces: _pieces,
                progress: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.spin,
    required this.decay,
    required this.startDelay,
    required this.isCircle,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double spin;
  final double decay;
  final double startDelay;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.progress});

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final piece in pieces) {
      final localT = ((progress - piece.startDelay) / (1 - piece.startDelay))
          .clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final travel = 1 - math.pow(1 - localT, piece.decay * 4).toDouble();
      final px = (piece.x + piece.vx * travel) * size.width;
      final py =
          (piece.y + piece.vy * travel + localT * localT * 0.55) * size.height;

      final alpha = (1 - localT * 0.95).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;

      paint.color = piece.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(piece.rotation + localT * piece.spin);

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size * 0.45, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
