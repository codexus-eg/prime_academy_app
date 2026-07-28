import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class RankingTrophyIcon extends StatefulWidget {
  const RankingTrophyIcon({
    super.key,
    required this.rank,
    this.size = 20,
  });

  final int rank;
  final double size;

  @override
  State<RankingTrophyIcon> createState() => _RankingTrophyIconState();
}

class _RankingTrophyIconState extends State<RankingTrophyIcon>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/icons/ranking/trophy_fill.svg';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color? get _iconColor => switch (widget.rank) {
        1 => AppColors.rankGold,
        2 => AppColors.rankSilver,
        3 => AppColors.rankBronze,
        _ => null,
      };

  Color? get _glowColor => switch (widget.rank) {
        1 => AppColors.rankGold,
        2 => AppColors.rankSilver,
        3 => AppColors.rankBronze,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final color = _iconColor;
    if (color == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = Curves.easeInOut.transform(
            (math.sin(_controller.value * math.pi * 2) + 1) / 2,
          );
          final blurSigma = phase * 2;
          final glowOpacity = 0.4 + (phase * 0.2);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_glowColor != null)
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Opacity(
                    opacity: glowOpacity,
                    child: _TrophySvg(
                      asset: _asset,
                      size: widget.size,
                      color: _glowColor!,
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: _TrophySvg(
          asset: _asset,
          size: widget.size,
          color: color,
        ),
      ),
    );
  }
}

class _TrophySvg extends StatelessWidget {
  const _TrophySvg({
    required this.asset,
    required this.size,
    required this.color,
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
