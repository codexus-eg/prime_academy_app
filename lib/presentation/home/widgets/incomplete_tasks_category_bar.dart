import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/incomplete_task.dart';
import 'incomplete_category_style.dart';
import 'incomplete_task_icons.dart';

class IncompleteTasksCategoryBar extends StatelessWidget {
  const IncompleteTasksCategoryBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final IncompleteTaskCategory selected;
  final Map<IncompleteTaskCategory, int> counts;
  final ValueChanged<IncompleteTaskCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final visible = IncompleteTaskCategory.values
        .where((category) => (counts[category] ?? 0) > 0)
        .toList();

    return SizedBox(
      height: AppSpacing.incompleteTaskTabBarHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: visible.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = visible[index];
          final count = counts[category] ?? 0;
          return _CategoryChip(
            category: category,
            count: count,
            isSelected: category == selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IncompleteTaskCategory category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = IncompleteCategoryStyle.forCategory(widget.category);
    final isSelected = widget.isSelected;
    final labelColor = isSelected
        ? IncompleteCategoryStyle.chipActiveText
        : _hovered
            ? IncompleteCategoryStyle.chipActiveText
            : IncompleteCategoryStyle.chipInactiveText;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.borderTailwindXl,
          child: Ink(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.smPlus,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? style.chipActiveGradient : null,
              color: isSelected ? null : IncompleteCategoryStyle.chipInactiveBackground,
              borderRadius: AppRadius.borderTailwindXl,
              border: Border.all(
                color: isSelected
                    ? IncompleteCategoryStyle.chipActiveBorder
                    : _hovered
                        ? IncompleteCategoryStyle.chipInactiveHoverBorder
                        : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? AppShadows.lg : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IncompleteTaskIcons.chipIcon(
                  widget.category,
                  isActive: isSelected,
                  hovered: _hovered,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.category.label,
                  style: AppTypography.custom(
                    fontSize: 14,
                    fontWeight: AppFonts.medium,
                    color: labelColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CountBadge(count: widget.count, isActive: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.isActive,
  });

  final int count;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? IncompleteCategoryStyle.countBadgeActiveBackground
            : IncompleteCategoryStyle.countBadgeInactiveBackground,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$count',
        style: AppTypography.custom(
          fontSize: 12,
          fontWeight: AppFonts.semibold,
          color: isActive
              ? IncompleteCategoryStyle.countBadgeActiveText
              : IncompleteCategoryStyle.countBadgeInactiveText,
          height: 1.2,
        ),
      ),
    );
  }
}
