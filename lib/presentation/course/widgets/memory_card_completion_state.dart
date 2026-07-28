import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glowing_trophy.dart';
import '../../luck_cards/data/luck_assets.dart';

class MemoryCardCompletionState extends StatefulWidget {
  const MemoryCardCompletionState({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<MemoryCardCompletionState> createState() =>
      _MemoryCardCompletionStateState();
}

class _MemoryCardCompletionStateState extends State<MemoryCardCompletionState>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _badgeController;
  late final AnimationController _titleController;
  late final AnimationController _buttonController;
  late final AnimationController _trophyController;

  late final Animation<double> _fade;
  late final Animation<Offset> _badgeSlide;
  late final Animation<double> _badgeOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<double> _trophyScale;
  late final Animation<double> _trophyRotate;
  late final Animation<double> _trophyOpacity;

  static const _trophyPop = Cubic(0.34, 1.56, 0.64, 1);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    Animation<Offset> slideTween(AnimationController c) => Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));

    _badgeSlide = slideTween(_badgeController);
    _badgeOpacity = CurvedAnimation(parent: _badgeController, curve: Curves.easeOut);
    _titleSlide = slideTween(_titleController);
    _titleOpacity = CurvedAnimation(parent: _titleController, curve: Curves.easeOut);
    _buttonSlide = slideTween(_buttonController);
    _buttonOpacity = CurvedAnimation(parent: _buttonController, curve: Curves.easeOut);

    _trophyScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.18).chain(CurveTween(curve: _trophyPop)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.94).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_trophyController);

    _trophyRotate = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.175, end: 0.087), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 0.087, end: -0.052), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.052, end: 0.0), weight: 25),
    ]).animate(_trophyController);

    _trophyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _trophyController,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _trophyController.forward();
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _badgeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _titleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _badgeController.dispose();
    _trophyController.dispose();
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleSize = (MediaQuery.sizeOf(context).width * 0.05)
        .clamp(30.0, 46.0)
        .toDouble();

    return Expanded(
      child: FadeTransition(
        opacity: _fade,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _badgeOpacity,
                child: SlideTransition(
                  position: _badgeSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.blue),
                        ),
                        child: Text(
                          'اكتملت المهمة',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.blue,
                            fontWeight: AppFonts.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _trophyController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _trophyOpacity.value,
                            child: Transform.rotate(
                              angle: _trophyRotate.value,
                              child: Transform.scale(
                                scale: _trophyScale.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: GlowingTrophy(asset: LuckAssets.trophyImage),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              FadeTransition(
                opacity: _titleOpacity,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Text(
                    'يا سلام عليك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              FadeTransition(
                opacity: _buttonOpacity,
                child: SlideTransition(
                  position: _buttonSlide,
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.5),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'العودة إلى الدرس',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: AppFonts.semibold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
