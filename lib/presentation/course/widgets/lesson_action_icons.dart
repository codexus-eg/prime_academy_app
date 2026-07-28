import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class LessonActionIcons {
  static const bookOpen = 'assets/icons/lesson/book_open.svg';
  static const comment = 'assets/icons/lesson/comment.svg';
  static const cards = 'assets/icons/lesson/cards.svg';
  static const rankingStar = 'assets/icons/lesson/ranking_star.svg';
  static const play = 'assets/icons/lesson/play.svg';
  static const checkmark = 'assets/icons/lesson/checkmark.svg';
  static const trophy = 'assets/icons/lesson/trophy.svg';
  static const dumbbell = 'assets/icons/lesson/dumbbell.svg';

  static Widget svg(
    String asset, {
    double size = 16,
    Color color = Colors.white,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
