import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icons/mystery_card_icon.dart';
import '../models/incomplete_task.dart';
import 'incomplete_category_style.dart';

abstract final class IncompleteTaskIcons {

  static Widget chipIcon(
    IncompleteTaskCategory category, {
    required bool isActive,
    bool hovered = false,
  }) {
    if (category == IncompleteTaskCategory.luckCards) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: MysteryCardIcon(
            size: 16,
            cardColor: AppColors.primary,
            symbolColor: Colors.black,
          ),
        ),
      );
    }

    return categoryIcon(
      category,
      size: 16,
      isActive: isActive,
      hovered: hovered,
    );
  }

  static Widget cardIcon(IncompleteTaskCategory category) {
    if (category == IncompleteTaskCategory.luckCards) {
      return const MysteryCardIcon(
        size: 28,
        cardColor: AppColors.primary,
        symbolColor: Colors.black,
      );
    }

    return categoryIcon(category, size: 20, isActive: true);
  }

  static Widget categoryIcon(
    IncompleteTaskCategory category, {
    double size = 18,
    bool isActive = true,
    bool hovered = false,
  }) {
    final style = IncompleteCategoryStyle.forCategory(category);
    final color = isActive
        ? style.accentText
        : hovered
            ? IncompleteCategoryStyle.chipActiveText
            : IncompleteCategoryStyle.chipInactiveIcon;

    // CSS `currentColor: rgba(...)` applies alpha as opacity. Flutter
    // ColorFilter.srcIn with an alpha color darkens the glyph; split them.
    final opacity = color.a;
    final painted = color.withValues(alpha: 1);
    Widget icon = SvgPicture.asset(
      style.iconAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(painted, BlendMode.srcIn),
    );
    if (opacity < 1) {
      icon = Opacity(opacity: opacity, child: icon);
    }
    return icon;
  }
}
