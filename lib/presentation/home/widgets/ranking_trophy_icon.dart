import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

/// Web `BsFillTrophyFill` from RankTable (`react-icons/bs`),
/// copied from Bootstrap Icons `trophy-fill.svg`.
class RankingTrophyIcon extends StatefulWidget {
  const RankingTrophyIcon({
    super.key,
    required this.rank,
  });

  final int rank;

  @override
  State<RankingTrophyIcon> createState() => _RankingTrophyIconState();
}

class _RankingTrophyIconState extends State<RankingTrophyIcon>
    with TickerProviderStateMixin {
  static const _asset = 'assets/icons/ranking/trophy_fill.svg';

  late final AnimationController _idle;
  late final AnimationController _hover;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _hover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (widget.rank == 1) {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RankingTrophyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rank == 1 && !_idle.isAnimating) {
      _idle.repeat();
    } else if (widget.rank != 1 && _idle.isAnimating) {
      _idle
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _hover.dispose();
    super.dispose();
  }

  Color? get _iconColor => switch (widget.rank) {
        1 => AppColors.rankGold,
        2 => AppColors.rankSilverLight,
        3 => AppColors.rankBronzeDark,
        _ => null,
      };

  double get _iconSize => widget.rank == 1 ? 20 : 16;

  @override
  Widget build(BuildContext context) {
    final color = _iconColor;
    if (color == null) {
      return const SizedBox(width: 20, height: 20);
    }

    return MouseRegion(
      onEnter: (_) => _hover.forward(),
      onExit: (_) => _hover.reverse(),
      child: SizedBox(
        width: 20,
        height: 20,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _hover]),
          builder: (context, child) {
            final pingPong = widget.rank == 1
                ? Curves.easeInOut.transform(
                    _idle.value <= 0.5
                        ? _idle.value * 2
                        : (1 - _idle.value) * 2,
                  )
                : 0.0;
            final hoverT = Curves.easeInOut.transform(_hover.value);
            final idleScale = 1.0 + (0.15 * pingPong);
            final scale = hoverT > 0
                ? 1.0 + (0.2 * hoverT)
                : idleScale;
            final rotation = hoverT * 10 * math.pi / 180;
            final glowBlur = 1.0 + (3.0 * pingPong);
            final glowOpacity = 0.6 + (0.3 * pingPong);

            return Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (widget.rank == 1)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: glowBlur,
                          sigmaY: glowBlur,
                        ),
                        child: Opacity(
                          opacity: glowOpacity,
                          child: _TrophySvg(
                            size: _iconSize,
                            color: AppColors.rankGold,
                          ),
                        ),
                      ),
                    child!,
                  ],
                ),
              ),
            );
          },
          child: _TrophySvg(
            size: _iconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TrophySvg extends StatelessWidget {
  const _TrophySvg({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _RankingTrophyIconState._asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
