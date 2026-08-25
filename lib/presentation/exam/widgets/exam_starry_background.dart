import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Owns the quiz backdrop ticker + glyphs so the full-screen layer and the
/// frosted card can paint the exact same moving symbols.
class ExamBackdropHost extends StatefulWidget {
  const ExamBackdropHost({super.key, required this.child});

  final Widget child;

  static ExamBackdropHostState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ExamBackdropScope>()?.state;
  }

  @override
  State<ExamBackdropHost> createState() => ExamBackdropHostState();
}

class ExamBackdropHostState extends State<ExamBackdropHost>
    with SingleTickerProviderStateMixin {
  final LayerLink layerLink = LayerLink();
  final ValueNotifier<double> tSec = ValueNotifier<double>(0);

  late final Ticker _ticker;
  List<_Glyph> _glyphs = const [];
  List<TextPainter> _textPainters = const [];
  bool? _wasMobile;
  int _generation = 0;

  static final _letters = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'.split('');
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
      tSec.value = elapsed.inMicroseconds / 1e6;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      tSec.value = 0;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    _ensureGlyphs(MediaQuery.sizeOf(context).width < 768);
  }

  @override
  void dispose() {
    _ticker.dispose();
    tSec.dispose();
    _disposePainters();
    super.dispose();
  }

  void _disposePainters() {
    for (final painter in _textPainters) {
      painter.dispose();
    }
    _textPainters = const [];
  }

  void _ensureGlyphs(bool mobile) {
    if (_wasMobile == mobile && _glyphs.isNotEmpty) return;
    final notify = _glyphs.isNotEmpty;
    _wasMobile = mobile;
    _disposePainters();

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

    _textPainters = [
      for (final glyph in _glyphs)
        TextPainter(
          text: TextSpan(text: glyph.text, style: _labelStyle(glyph)),
          textDirection: glyph.kind == _GlyphKind.letter
              ? TextDirection.rtl
              : TextDirection.ltr,
          maxLines: 1,
        )..layout(),
    ];
    if (notify) {
      _generation++;
      setState(() {});
    }
  }

  CustomPainter createPainter() {
    return _QuizBackgroundPainter(
      tSec: tSec,
      glyphs: _glyphs,
      painters: _textPainters,
      mobile: _wasMobile ?? true,
    );
  }

  static TextStyle _labelStyle(_Glyph glyph) {
    final color = glyph.color.withValues(alpha: glyph.color.a * glyph.baseOpacity);
    switch (glyph.kind) {
      case _GlyphKind.letter:
        return TextStyle(
          fontFamily: AppFonts.bahij,
          fontSize: glyph.size,
          fontWeight: FontWeight.w600,
          height: 1,
          color: color,
        );
      case _GlyphKind.math:
        return TextStyle(
          fontSize: glyph.size,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          height: 1,
          color: color,
          fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
        );
      case _GlyphKind.chem:
        return TextStyle(
          fontSize: glyph.size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1,
          color: color,
          fontFamilyFallback: const ['Courier New', 'monospace'],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ExamBackdropScope(
      state: this,
      generation: _generation,
      child: widget.child,
    );
  }
}

class _ExamBackdropScope extends InheritedWidget {
  const _ExamBackdropScope({
    required this.state,
    required this.generation,
    required super.child,
  });

  final ExamBackdropHostState state;
  final int generation;

  @override
  bool updateShouldNotify(_ExamBackdropScope oldWidget) {
    return oldWidget.generation != generation;
  }
}

class ExamStarryBackground extends StatelessWidget {
  const ExamStarryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final host = ExamBackdropHost.maybeOf(context);
    if (host == null) return const ColoredBox(color: AppColors.examStarryBg);

    return IgnorePointer(
      child: CompositedTransformTarget(
        link: host.layerLink,
        child: CustomPaint(
          painter: host.createPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

double cssLinearPingPong(double tSec, double durationSec, double delaySec) {
  var cycle = (tSec - delaySec) / durationSec;
  cycle -= cycle.floorToDouble();
  if (cycle < 0) cycle += 1;
  return cycle <= 0.5 ? cycle * 2.0 : (1.0 - cycle) * 2.0;
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
    required this.tSec,
    required this.glyphs,
    required this.painters,
    required this.mobile,
  }) : super(repaint: tSec);

  final ValueNotifier<double> tSec;
  final List<_Glyph> glyphs;
  final List<TextPainter> painters;
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

    final t = tSec.value;

    if (!mobile) {
      final driftA = cssLinearPingPong(t, 60, 0);
      canvas.save();
      canvas.translate(30 * driftA, -15 * driftA);
      _paintRadial(
        canvas,
        size,
        center: Offset(size.width * 0.20, size.height * 0.30),
        radius: size.shortestSide * 0.9,
        color: const Color.fromRGBO(0, 110, 230, 0.05),
      );
      _paintRadial(
        canvas,
        size,
        center: Offset(size.width * 0.80, size.height * 0.70),
        radius: size.shortestSide * 0.8,
        color: const Color.fromRGBO(120, 70, 220, 0.04),
      );
      canvas.restore();

      final driftB = cssLinearPingPong(t, 70, 0);
      canvas.save();
      canvas.translate(-20 * driftB, 20 * driftB);
      _paintRadial(
        canvas,
        size,
        center: Offset(size.width * 0.50, size.height * 0.20),
        radius: size.shortestSide * 0.75,
        color: const Color.fromRGBO(220, 135, 0, 0.03),
      );
      canvas.restore();
    }

    for (var i = 0; i < glyphs.length; i++) {
      final glyph = glyphs[i];
      final tp = painters[i];
      final tri = cssLinearPingPong(t, glyph.durationSec, glyph.delaySec);
      final rot =
          (glyph.rotationDeg + glyph.rotationDeltaDeg * tri) * math.pi / 180;
      final cx = glyph.left * size.width + glyph.moveX * tri;
      final cy = glyph.top * size.height + glyph.moveY * tri;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _QuizBackgroundPainter oldDelegate) {
    return oldDelegate.glyphs != glyphs ||
        oldDelegate.painters != painters ||
        oldDelegate.mobile != mobile;
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
