import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

abstract final class RankingIcons {
  static const trophyFill = 'assets/icons/ranking/trophy_fill.svg';
  static const studentFill = 'assets/icons/ranking/student_fill.svg';

  static Color trophyColor(int rank) => switch (rank) {
        1 => AppColors.rankGold,
        2 => AppColors.rankSilver,
        3 => AppColors.rankBronze,
        _ => AppColors.transparent,
      };

  static Widget trophy({
    required int rank,
    double size = 16,
  }) {
    final color = trophyColor(rank);
    if (color == AppColors.transparent) {
      return SizedBox(width: size, height: size);
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: svg(trophyFill, size: size, color: color),
      ),
    );
  }

  static Widget svg(
    String asset, {
    double size = 16,
    Color color = Colors.white,
  }) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
