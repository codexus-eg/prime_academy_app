import 'package:flutter/material.dart';

import '../../../core/theme/app_durations.dart';
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

    // Web: flex gap-2 overflow-x-auto, button height ~44px (py-2.5 + text-sm).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            _CategoryChip(
              category: visible[i],
              count: counts[visible[i]] ?? 0,
              isSelected: visible[i] == selected,
              onTap: () => onSelected(visible[i]),
            ),
          ],
        ],
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
  var _pressed = false;

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
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: AppDurations.tab,
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.smPlus,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? style.chipActiveGradient : null,
              color: isSelected
                  ? null
                  : IncompleteCategoryStyle.chipInactiveBackground,
              borderRadius: AppRadius.borderTailwindXl,
              border: Border.all(
                color: isSelected
                    ? IncompleteCategoryStyle.chipActiveBorder
                    : _hovered
                        ? IncompleteCategoryStyle.chipInactiveHoverBorder
                        : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? AppShadows.tailwindLg : null,
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
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
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.custom(
                      // Web `text-sm font-medium`. Bahij only has 300/700;
                      // browsers map 500 → SemiLight (300).
                      fontSize: 14,
                      fontWeight: AppFonts.regular,
                      color: labelColor,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CountBadge(count: widget.count, isActive: isSelected),
                ],
              ),
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
        vertical: 2,
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
          // Web `text-xs font-semibold`. Bahij maps 600 → Bold (700).
          fontSize: 12,
          fontWeight: AppFonts.bold,
          color: isActive
              ? IncompleteCategoryStyle.countBadgeActiveText
              : IncompleteCategoryStyle.countBadgeInactiveText,
          height: 16 / 12,
        ),
      ),
    );
  }
}
