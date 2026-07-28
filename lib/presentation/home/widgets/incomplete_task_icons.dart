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
      return SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: MysteryCardIcon(
            size: 20,
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

    return categoryIcon(category, size: 22, isActive: true);
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

    return SvgPicture.asset(
      style.iconAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
