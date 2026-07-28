import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class ReportInlineIcon extends StatelessWidget {
  const ReportInlineIcon({
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

class ReportAwardIcon extends StatelessWidget {
  const ReportAwardIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="m15.477 12.89 1.515 8.526a.5.5 0 0 1-.81.47l-3.58-2.687a1 1 0 0 0-1.197 0l-3.586 2.686a.5.5 0 0 1-.81-.469l1.514-8.526"/>
  <circle stroke="#000000" stroke-width="2" cx="12" cy="8" r="6"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.blueLight,
    );
  }
}

class ReportClockIcon extends StatelessWidget {
  const ReportClockIcon({super.key, this.size = 14, this.color});

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <circle stroke="#000000" stroke-width="2" cx="12" cy="12" r="10"/>
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M12 6v6l4 2"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.textMuted,
    );
  }
}

class ReportRibbonIcon extends StatelessWidget {
  const ReportRibbonIcon({super.key, this.size = 26, this.color});

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512">
  <path fill="#000000" d="M6.1 444.3c-9.6 10.8-7.5 27.6 4.5 35.7l68.8 27.9c9.9 6.7 23.3 5 31.3-3.8l91.8-101.9-79.2-87.9-117.2 130zm435.8 0s-292-324.6-295.4-330.1c15.4-8.4 40.2-17.9 77.5-17.9s62.1 9.5 77.5 17.9c-3.3 5.6-56 64.6-56 64.6l79.1 87.7 34.2-38c28.7-31.9 33.3-78.6 11.4-115.5l-43.7-73.5c-4.3-7.2-9.9-13.3-16.8-18-40.7-27.6-127.4-29.7-171.4 0-6.9 4.7-12.5 10.8-16.8 18l-43.6 73.2c-1.5 2.5-37.1 62.2 11.5 116L337.5 504c8 8.9 21.4 10.5 31.3 3.8l68.8-27.9c11.9-8 14-24.8 4.3-35.6z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.blueLight,
    );
  }
}

class ReportExamFillIcon extends StatelessWidget {
  const ReportExamFillIcon({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <path fill="#000000" d="M96,113.89,107.06,136H84.94ZM232,56V216a8,8,0,0,1-11.58,7.16L192,208.94l-28.42,14.22a8,8,0,0,1-7.16,0L128,208.94,99.58,223.16a8,8,0,0,1-7.16,0L64,208.94,35.58,223.16A8,8,0,0,1,24,216V56A16,16,0,0,1,40,40H216A16,16,0,0,1,232,56ZM135.16,156.42l-32-64a8,8,0,0,0-14.32,0l-32,64a8,8,0,0,0,14.32,7.16L76.94,152h38.12l5.78,11.58a8,8,0,1,0,14.32-7.16ZM208,128a8,8,0,0,0-8-8H184V104a8,8,0,0,0-16,0v16H152a8,8,0,0,0,0,16h16v16a8,8,0,0,0,16,0V136h16A8,8,0,0,0,208,128Z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.blueLight,
    );
  }
}

class ReportGradeIcon extends StatelessWidget {
  const ReportGradeIcon({
    super.key,
    required this.color,
    this.size = 18,
  });

  final double size;
  final Color color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#000000" d="M12 17.27 18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(svg: _svg, size: size, color: color);
  }
}

class ReportTrophyFillIcon extends StatelessWidget {
  const ReportTrophyFillIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  final double size;
  final Color color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <path fill="#000000" d="M2.5.5A.5.5 0 0 1 3 0h10a.5.5 0 0 1 .5.5q0 .807-.034 1.536a3 3 0 1 1-1.133 5.89c-.79 1.865-1.878 2.777-2.833 3.011v2.173l1.425.356c.194.048.377.135.537.255L13.3 15.1a.5.5 0 0 1-.3.9H3a.5.5 0 0 1-.3-.9l1.838-1.379c.16-.12.343-.207.537-.255L6.5 13.11v-2.173c-.955-.234-2.043-1.146-2.833-3.012a3 3 0 1 1-1.132-5.89A33 33 0 0 1 2.5.5m.099 2.54a2 2 0 0 0 .72 3.935c-.333-1.05-.588-2.346-.72-3.935m10.083 3.935a2 2 0 0 0 .72-3.935c-.133 1.59-.388 2.885-.72 3.935"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(svg: _svg, size: size, color: color);
  }
}

class ReportChevronLeftIcon extends StatelessWidget {
  const ReportChevronLeftIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="m15 18-6-6 6-6"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.blueLight,
      semanticsLabel: 'فتح تقرير الطالب',
    );
  }
}

class ReportDocumentTextIcon extends StatelessWidget {
  const ReportDocumentTextIcon({
    super.key,
    this.size = 40,
    this.color,
  });

  final double size;
  final Color? color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
  <path fill="#000000" fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 6a1 1 0 011-1h6a1 1 0 110 2H7a1 1 0 01-1-1zm1 3a1 1 0 100 2h6a1 1 0 100-2H7z" clip-rule="evenodd"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ReportInlineIcon(
      svg: _svg,
      size: size,
      color: color ?? AppColors.blueLight.withValues(alpha: 0.5),
      semanticsLabel: 'لا توجد تقارير',
    );
  }
}
