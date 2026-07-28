import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class KnowledgeQuizBackground extends StatefulWidget {
  const KnowledgeQuizBackground({super.key});

  @override
  State<KnowledgeQuizBackground> createState() => _KnowledgeQuizBackgroundState();
}

class _KnowledgeQuizBackgroundState extends State<KnowledgeQuizBackground>
    with SingleTickerProviderStateMixin {
  late final List<_Particle> _particles;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    final random = math.Random(42);
    _particles = List.generate(40, (i) {
      return _Particle(
        width: random.nextDouble() * 5 + 1.5,
        height: random.nextDouble() * 5 + 1.5,
        top: random.nextDouble(),
        left: random.nextDouble(),
        phase: random.nextDouble() * math.pi * 2,
        speed: random.nextDouble() * 0.4 + 0.6,
      );
    });
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return ColoredBox(
      color: AppColors.mainBg3,
      child: Stack(
        fit: StackFit.expand,
        children: [

          const Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          const Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: CustomPaint(painter: _MysteryPatternPainter()),
            ),
          ),

          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    Color(0x241A74C8),
                    Color(0x00000000),
                  ],
                  stops: [0, 0.6],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return Stack(
                  children: [
                    for (final particle in _particles)
                      _FloatingParticle(
                        particle: particle,
                        t: _floatController.value,
                      ),
                  ],
                );
              },
            ),
          ),

          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1,
                  colors: [
                    Color(0x00000000),
                    Color(0x66000000),
                  ],
                  stops: [0.4, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.width,
    required this.height,
    required this.top,
    required this.left,
    required this.phase,
    required this.speed,
  });

  final double width;
  final double height;
  final double top;
  final double left;
  final double phase;
  final double speed;
}

class _FloatingParticle extends StatelessWidget {
  const _FloatingParticle({required this.particle, required this.t});

  final _Particle particle;
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wave = math.sin((t * particle.speed * math.pi * 2) + particle.phase);
    final drift = math.cos((t * particle.speed * math.pi) + particle.phase);
    final opacity = 0.7 + (wave * 0.15);

    return Positioned(
      left: particle.left * size.width + drift * 12,
      top: particle.top * size.height + wave * -25,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: particle.width,
          height: particle.height,
          decoration: const BoxDecoration(
            color: Color(0x4DFFFFFF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const step = 80.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MysteryPatternPainter extends CustomPainter {
  const _MysteryPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 120.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const questionColor = Color.fromRGBO(255, 255, 255, 0.21);

    const sparkleColor = Color.fromRGBO(255, 255, 255, 0.3);
    final dotPaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.3);

    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        textPainter.text = TextSpan(
          text: '?',
          style: TextStyle(
            color: questionColor,
            fontSize: 28,
            fontFamily: 'sans-serif',
          ),
        );
        textPainter.layout();

        textPainter.paint(canvas, Offset(x + 20, y + 22));

        textPainter.text = TextSpan(
          text: '✦',
          style: TextStyle(
            color: sparkleColor,
            fontSize: 20,
          ),
        );
        textPainter.layout();

        textPainter.paint(canvas, Offset(x + 70, y + 70));

        canvas.drawCircle(Offset(x + 90, y + 30), 3, dotPaint);
        canvas.drawCircle(Offset(x + 100, y + 40), 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
