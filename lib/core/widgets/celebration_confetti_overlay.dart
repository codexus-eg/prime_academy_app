import 'dart:math' as math;

import 'package:flutter/material.dart';

class CelebrationConfettiOverlay extends StatefulWidget {
  const CelebrationConfettiOverlay({super.key, required this.trigger});

  final int trigger;

  @override
  State<CelebrationConfettiOverlay> createState() =>
      _CelebrationConfettiOverlayState();
}

class _CelebrationConfettiOverlayState extends State<CelebrationConfettiOverlay>
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
  late List<_ConfettiPiece> _pieces;
  var _lastTrigger = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pieces = const [];
  }

  @override
  void didUpdateWidget(covariant CelebrationConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != _lastTrigger && widget.trigger > 0) {
      _lastTrigger = widget.trigger;
      _launch();
    }
  }

  void _launch() {
    final random = math.Random();
    final pieces = <_ConfettiPiece>[];

    const waves = [
      (ratio: 0.25, spread: 26.0, velocity: 55.0, scalar: 1.0, delay: 0.0),
      (ratio: 0.20, spread: 60.0, velocity: 45.0, scalar: 1.0, delay: 0.04),
      (ratio: 0.35, spread: 100.0, velocity: 50.0, scalar: 0.8, delay: 0.08),
      (ratio: 0.10, spread: 120.0, velocity: 25.0, scalar: 1.2, delay: 0.12),
      (ratio: 0.10, spread: 120.0, velocity: 45.0, scalar: 1.0, delay: 0.16),
    ];

    for (final wave in waves) {
      final count = (200 * wave.ratio).floor();
      for (var i = 0; i < count; i++) {
        final spreadRad = wave.spread * math.pi / 180;
        final angle = (random.nextDouble() - 0.5) * spreadRad + math.pi * 1.5;
        final speed = (wave.velocity / 100) * (0.75 + random.nextDouble() * 0.5);
        pieces.add(
          _ConfettiPiece(
            x: 0.5 + (random.nextDouble() - 0.5) * 0.08,
            y: 0.6,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 0.25,
            size: (random.nextDouble() * 6 + 4) * wave.scalar,
            color: _colors[random.nextInt(_colors.length)],
            rotation: random.nextDouble() * math.pi,
            startDelay: wave.delay,
            decay: 0.88 + random.nextDouble() * 0.08,
          ),
        );
      }
    }

    setState(() => _pieces = pieces);
    _controller.forward(from: 0);
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
              painter: _CelebrationConfettiPainter(
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
    required this.startDelay,
    required this.decay,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double startDelay;
  final double decay;
}

class _CelebrationConfettiPainter extends CustomPainter {
  const _CelebrationConfettiPainter({
    required this.pieces,
    required this.progress,
  });

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final localT = ((progress - piece.startDelay) / (1 - piece.startDelay))
          .clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final dampedT = 1 - math.pow(1 - localT, piece.decay * 3).toDouble();
      final px = (piece.x + piece.vx * dampedT) * size.width;
      final py = (piece.y + piece.vy * dampedT + dampedT * dampedT * 0.2) *
          size.height;

      paint.color = piece.color.withValues(alpha: (1 - localT).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(piece.rotation + dampedT * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.55,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
