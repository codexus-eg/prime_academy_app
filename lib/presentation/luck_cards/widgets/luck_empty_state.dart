import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glowing_trophy.dart';
import '../data/luck_assets.dart';

class LuckEmptyState extends StatefulWidget {
  const LuckEmptyState({super.key, required this.onExit});

  final VoidCallback onExit;

  @override
  State<LuckEmptyState> createState() => _LuckEmptyStateState();
}

class _LuckEmptyStateState extends State<LuckEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _trophyController;
  late final Animation<double> _trophyScale;
  late final Animation<double> _trophyRotate;
  late final Animation<double> _trophyOpacity;

  @override
  void initState() {
    super.initState();
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _trophyScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.94), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 25),
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

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _trophyController.forward();
    });
  }

  @override
  void dispose() {
    _trophyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
            const SizedBox(height: AppSpacing.xl),
            Text(
              'لا توجد أسئلة متاحة',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(
                color: Colors.white,
                fontWeight: AppFonts.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: widget.onExit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Text(
                'خروج',
                style: AppTypography.bodySm.copyWith(
                  fontWeight: AppFonts.semibold,
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
