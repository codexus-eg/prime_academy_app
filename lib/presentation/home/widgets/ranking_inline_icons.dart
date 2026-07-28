import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class RankingInlineIcon extends StatelessWidget {
  const RankingInlineIcon({
    super.key,
    required this.svg,
    required this.size,
    required this.color,
    this.semanticsLabel,
  });

  final String svg;
  final double size;
  final Color color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class RankingMedalIcon extends StatelessWidget {
  const RankingMedalIcon({
    super.key,
    this.size = 20,
    this.color,
  });

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M7.21 15 2.66 7.14a2 2 0 0 1 .13-2.2L4.4 2.8A2 2 0 0 1 6 2h12a2 2 0 0 1 1.6.8l1.6 2.14a2 2 0 0 1 .14 2.2L16.79 15"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M11 12 5.12 2.2"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="m13 12 5.88-9.8"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M8 7h8"/>
  <circle stroke="#000000" stroke-width="2" cx="12" cy="17" r="5"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M12 18v-2h-.5"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return RankingInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.blueLight,
    );
  }
}

class RankingUsersIcon extends StatelessWidget {
  const RankingUsersIcon({
    super.key,
    this.size = 14,
    this.color,
  });

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M16 3.128a4 4 0 0 1 0 7.744"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M22 21v-2a4 4 0 0 0-3-3.87"/>
  <circle stroke="#000000" stroke-width="2" cx="9" cy="7" r="4"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return RankingInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.textMuted,
    );
  }
}

class RankingSearchIcon extends StatelessWidget {
  const RankingSearchIcon({
    super.key,
    this.size = 20,
    this.color,
  });

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <circle stroke="#000000" stroke-width="2" cx="11" cy="11" r="8"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" d="m21 21-4.3-4.3"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return RankingInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.textMuted.withValues(alpha: 0.5),
    );
  }
}

class RankingClearSearchIcon extends StatelessWidget {
  const RankingClearSearchIcon({
    super.key,
    this.size = 16,
    this.color,
  });

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" d="M18 6 6 18"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" d="m6 6 12 12"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return RankingInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.textMuted.withValues(alpha: 0.5),
    );
  }
}
