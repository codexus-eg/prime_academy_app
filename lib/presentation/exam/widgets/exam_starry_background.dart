import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

class ExamStarryBackground extends StatefulWidget {
  const ExamStarryBackground({super.key});

  @override
  State<ExamStarryBackground> createState() => _ExamStarryBackgroundState();
}

class _ExamStarryBackgroundState extends State<ExamStarryBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  List<_Glyph> _glyphs = const [];
  bool? _wasMobile;

  static final _letters =
      'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'.split('');
  static const _math = [
    '+', '−', '×', '÷', '=', '≈', '≠', '≤', '≥', 'π', '∑', '∫', '√', '∞',
    '%', 'Δ', 'θ', 'α', 'β', 'λ', '∂', '∇', '²', '³',
  ];
  static const _chem = [
    'H', 'He', 'Li', 'C', 'N', 'O', 'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl',
    'K', 'Ca', 'Fe', 'Cu', 'Zn', 'Ag', 'Au', 'Pb', 'U', 'H₂O', 'CO₂', 'NaCl',
    'O₂', 'CH₄', 'NH₃',
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsed = elapsed;
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureGlyphs(bool mobile) {
    if (_wasMobile == mobile && _glyphs.isNotEmpty) return;
    _wasMobile = mobile;
    final random = math.Random();
    final count = mobile ? 45 : 70;
    _glyphs = List.generate(count, (_) {
      final type = random.nextDouble();
      final variant = type < 0.4
          ? _GlyphKind.letter
          : type < 0.75
              ? _GlyphKind.math
              : _GlyphKind.chem;
      final pool = switch (variant) {
        _GlyphKind.letter => _letters,
        _GlyphKind.math => _math,
        _GlyphKind.chem => _chem,
      };

      final Color color;
      if (random.nextDouble() < 0.05) {
        color = const Color.fromRGBO(120, 180, 255, 0.9);
      } else if (random.nextDouble() < 0.03) {
        color = const Color.fromRGBO(200, 160, 255, 0.9);
      } else {
        color = const Color.fromRGBO(255, 255, 255, 0.6);
      }

      return _Glyph(
        text: pool[random.nextInt(pool.length)],
        kind: variant,
        left: random.nextDouble(),
        top: random.nextDouble(),
        size: random.nextDouble() * 14 + 9,
        baseOpacity: random.nextDouble() * 0.4 + 0.3,
        durationSec: mobile
            ? random.nextDouble() * 16 + 10
            : random.nextDouble() * 12 + 6,
        delaySec: random.nextDouble() * -6,
        moveX: (random.nextDouble() - 0.5) * (mobile ? 16 : 20),
        moveY: (random.nextDouble() - 0.5) * (mobile ? 13 : 15),
        rotationDeg: (random.nextDouble() - 0.5) * (mobile ? 13 : 16),
        rotationDeltaDeg: mobile ? 0.0 : (random.nextDouble() > 0.5 ? 8.0 : -8.0),
        color: color,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 768;
    _ensureGlyphs(mobile);
    final tSec = _elapsed.inMicroseconds / 1e6;

    return IgnorePointer(
      child: CustomPaint(
        painter: _QuizBackgroundPainter(
          glyphs: _glyphs,
          tSec: tSec,
          mobile: mobile,
        ),
        size: Size.infinite,
      ),
    );
  }
}

enum _GlyphKind { letter, math, chem }

class _Glyph {
  const _Glyph({
    required this.text,
    required this.kind,
    required this.left,
    required this.top,
    required this.size,
    required this.baseOpacity,
    required this.durationSec,
    required this.delaySec,
    required this.moveX,
    required this.moveY,
    required this.rotationDeg,
    required this.rotationDeltaDeg,
    required this.color,
  });

  final String text;
  final _GlyphKind kind;
  final double left;
  final double top;
  final double size;
  final double baseOpacity;
  final double durationSec;
  final double delaySec;
  final double moveX;
  final double moveY;
  final double rotationDeg;
  final double rotationDeltaDeg;
  final Color color;
}

class _QuizBackgroundPainter extends CustomPainter {
  _QuizBackgroundPainter({
    required this.glyphs,
    required this.tSec,
    required this.mobile,
  });

  final List<_Glyph> glyphs;
  final double tSec;
  final bool mobile;

  @override
  void paint(Canvas canvas, Size size) {

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.examStarryBg,
    );

    _paintRadial(
      canvas,
      size,
      center: Offset(size.width * 0.15, size.height * 0.25),
      radius: size.shortestSide * 0.75,
      color: const Color.fromRGBO(0, 110, 230, 0.12),
    );
    _paintRadial(
      canvas,
      size,
      center: Offset(size.width * 0.80, size.height * 0.60),
      radius: size.shortestSide * 0.65,
      color: const Color.fromRGBO(120, 70, 220, 0.09),
    );
    _paintRadial(
      canvas,
      size,
      center: Offset(size.width * 0.50, size.height * 0.85),
      radius: size.shortestSide * 0.55,
      color: const Color.fromRGBO(220, 135, 0, 0.06),
    );

    if (!mobile) {
      _paintDriftBlob(
        canvas,
        size,
        tSec: tSec,
        durationSec: 60,
        dx: 30,
        dy: -15,
        blur: 40,
        centers: [
          (
            Offset(size.width * 0.20, size.height * 0.30),
            size.shortestSide * 0.9,
            const Color.fromRGBO(0, 110, 230, 0.05),
          ),
          (
            Offset(size.width * 0.80, size.height * 0.70),
            size.shortestSide * 0.8,
            const Color.fromRGBO(120, 70, 220, 0.04),
          ),
        ],
      );
      _paintDriftBlob(
        canvas,
        size,
        tSec: tSec,
        durationSec: 70,
        dx: -20,
        dy: 20,
        blur: 50,
        centers: [
          (
            Offset(size.width * 0.50, size.height * 0.20),
            size.shortestSide * 0.75,
            const Color.fromRGBO(220, 135, 0, 0.03),
          ),
        ],
      );
    }

    for (final g in glyphs) {
      var cycle = (tSec - g.delaySec) / g.durationSec;
      cycle -= cycle.floorToDouble();
      final tri = cycle <= 0.5 ? cycle * 2.0 : (1.0 - cycle) * 2.0;
      final opacity = (g.baseOpacity * (1.0 - 0.5 * tri)).clamp(0.0, 1.0);
      final dx = g.moveX * tri;
      final dy = g.moveY * tri;
      final rot = (g.rotationDeg + g.rotationDeltaDeg * tri) * math.pi / 180;

      final tp = TextPainter(
        text: TextSpan(text: g.text, style: _style(g, opacity)),
        textDirection:
            g.kind == _GlyphKind.letter ? TextDirection.rtl : TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final cx = g.left * size.width + dx;
      final cy = g.top * size.height + dy;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  TextStyle _style(_Glyph g, double opacity) {
    final color = g.color.withValues(alpha: g.color.a * opacity);
    switch (g.kind) {
      case _GlyphKind.letter:
        return TextStyle(
          fontFamily: AppFonts.bahij,
          fontSize: g.size,
          fontWeight: FontWeight.w600,
          height: 1,
          color: color,
        );
      case _GlyphKind.math:
        return TextStyle(
          fontSize: g.size,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          height: 1,
          color: color,
          fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
        );
      case _GlyphKind.chem:
        return TextStyle(
          fontSize: g.size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1,
          color: color,
          fontFamilyFallback: const ['Courier New', 'monospace'],
        );
    }
  }

  void _paintRadial(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [color, color.withValues(alpha: 0)],
        const [0.0, 1.0],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintDriftBlob(
    Canvas canvas,
    Size size, {
    required double tSec,
    required double durationSec,
    required double dx,
    required double dy,
    required double blur,
    required List<(Offset, double, Color)> centers,
  }) {
    var cycle = tSec / durationSec;
    cycle -= cycle.floorToDouble();
    final tri = cycle <= 0.5 ? cycle * 2.0 : (1.0 - cycle) * 2.0;

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
    );
    canvas.translate(dx * tri, dy * tri);
    for (final (center, radius, color) in centers) {
      _paintRadial(canvas, size, center: center, radius: radius, color: color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QuizBackgroundPainter oldDelegate) {
    return oldDelegate.tSec != tSec ||
        oldDelegate.mobile != mobile ||
        !identical(oldDelegate.glyphs, glyphs);
  }
}
