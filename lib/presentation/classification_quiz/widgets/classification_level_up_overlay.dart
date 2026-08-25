import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';
import '../data/classification_sounds.dart';
import '../models/classification_level.dart';

/// Full-screen celebration shown when the student reaches a new classification.
/// Matches web `LevelUpCelebration`: dim overlay, flash, character image, title.
class ClassificationLevelUpOverlay extends StatefulWidget {
  const ClassificationLevelUpOverlay({
    super.key,
    required this.level,
    required this.onDone,
  });

  final ClassificationLevel level;
  final VoidCallback onDone;

  @override
  State<ClassificationLevelUpOverlay> createState() =>
      _ClassificationLevelUpOverlayState();
}

enum _LevelUpStage { flash, reveal, done }

class _ClassificationLevelUpOverlayState
    extends State<ClassificationLevelUpOverlay>
    with TickerProviderStateMixin {
  static const _confettiColors = [
    Color(0xFFFACC15),
    Color(0xFFF97316),
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
    Color(0xFF4ADE80),
  ];

  var _stage = _LevelUpStage.flash;
  final _timers = <Timer>[];
  late final AnimationController _fadeController;
  late final AnimationController _burstController;
  late final List<_BurstPiece> _confetti;
  late final List<_BurstPiece> _sparkles;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final random = math.Random(widget.level.imageIndex);
    _confetti = List.generate(20, (i) {
      final angle = (i / 20) * math.pi * 2;
      final distance = 90 + random.nextDouble() * 60;
      return _BurstPiece(
        dx: math.cos(angle) * distance,
        dy: math.sin(angle) * distance,
        rotate: random.nextDouble() * 360,
        width: 6 + random.nextDouble() * 5,
        height: 10 + random.nextDouble() * 6,
        delay: i * 0.025,
        color: _confettiColors[i % _confettiColors.length],
        circle: false,
      );
    });
    _sparkles = List.generate(10, (i) {
      final angle = (i / 10) * math.pi * 2;
      return _BurstPiece(
        dx: math.cos(angle) * 100,
        dy: math.sin(angle) * 100,
        rotate: 0,
        width: 6,
        height: 6,
        delay: i * 0.04,
        color: const Color(0xFFFACC15),
        circle: true,
      );
    });

    _timers.addAll([
      Timer(const Duration(milliseconds: 700), _reveal),
      Timer(const Duration(milliseconds: 5500), () {
        if (mounted) setState(() => _stage = _LevelUpStage.done);
      }),
      Timer(const Duration(milliseconds: 5800), () {
        if (mounted) widget.onDone();
      }),
    ]);
  }

  Future<void> _reveal() async {
    if (!mounted) return;
    setState(() => _stage = _LevelUpStage.reveal);
    _burstController.forward(from: 0);
    HapticFeedback.mediumImpact();
    await ClassificationSounds.playLevelUp();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _fadeController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageIndex = widget.level.imageIndex.clamp(
      0,
      ClassificationAssets.characterImages.length - 1,
    );
    final image = ClassificationAssets.characterImages[imageIndex];
    final size = math.min(320.0, MediaQuery.sizeOf(context).width - 64);
    final revealed =
        _stage == _LevelUpStage.reveal || _stage == _LevelUpStage.done;

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeController,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_stage == _LevelUpStage.flash)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.blue,
                            Color(0x00000000),
                          ],
                          radius: 0.7,
                        ),
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'وصلت لتصنيف أعلى',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.size20.copyWith(
                              color: Colors.white,
                              fontWeight: AppFonts.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: size,
                            height: size,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedOpacity(
                                  opacity: revealed ? 1 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Image.asset(
                                    image,
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                if (_stage == _LevelUpStage.reveal)
                                  AnimatedBuilder(
                                    animation: _burstController,
                                    builder: (context, _) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          for (final piece in [
                                            ..._confetti,
                                            ..._sparkles,
                                          ])
                                            _BurstDot(
                                              piece: piece,
                                              progress: _burstController.value,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: AnimatedOpacity(
                              opacity: revealed ? 1 : 0,
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                widget.level.title,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: AppTypography.size24.copyWith(
                                  color: Colors.white,
                                  fontWeight: AppFonts.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPiece {
  const _BurstPiece({
    required this.dx,
    required this.dy,
    required this.rotate,
    required this.width,
    required this.height,
    required this.delay,
    required this.color,
    required this.circle,
  });

  final double dx;
  final double dy;
  final double rotate;
  final double width;
  final double height;
  final double delay;
  final Color color;
  final bool circle;
}

class _BurstDot extends StatelessWidget {
  const _BurstDot({required this.piece, required this.progress});

  final _BurstPiece piece;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final local = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
    final curved = Curves.easeInOut.transform(local);
    return Transform.translate(
      offset: Offset(piece.dx * curved, piece.dy * curved),
      child: Transform.rotate(
        angle: piece.rotate * curved * math.pi / 180,
        child: Opacity(
          opacity: 1 - curved,
          child: Transform.scale(
            scale: piece.circle ? 1 - curved : 1 - curved * 0.6,
            child: Container(
              width: piece.width,
              height: piece.height,
              decoration: BoxDecoration(
                color: piece.color,
                borderRadius: BorderRadius.circular(piece.circle ? 99 : 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
