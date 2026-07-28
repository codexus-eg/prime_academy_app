import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LessonCheckMark extends StatelessWidget {
  const LessonCheckMark({
    super.key,
    required this.color,
    this.size = 10,
  });

  final Color color;
  final double size;

  static const assetPath = 'assets/images/lesson_check_mark.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
