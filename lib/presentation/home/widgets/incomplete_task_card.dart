import 'package:flutter/material.dart';

import '../../../core/widgets/icons/lucide_chevron_left_icon.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/incomplete_task.dart';
import 'incomplete_category_style.dart';
import 'incomplete_task_icons.dart';

class IncompleteTaskCard extends StatefulWidget {
  const IncompleteTaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  final IncompleteTask task;
  final VoidCallback? onTap;

  @override
  State<IncompleteTaskCard> createState() => _IncompleteTaskCardState();
}

class _IncompleteTaskCardState extends State<IncompleteTaskCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = IncompleteCategoryStyle.forCategory(widget.task.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: IncompleteCategoryStyle.cardBackground,
        borderRadius: AppRadius.borderAuthForm,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.borderAuthForm,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderAuthForm,
              gradient: _hovered
                  ? LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        style.cardHoverTint,
                        Colors.transparent,
                      ],
                    )
                  : null,
              color: _hovered ? null : IncompleteCategoryStyle.cardBackground,
              border: Border.all(
                color: _hovered
                    ? IncompleteCategoryStyle.cardBorderHover
                    : IncompleteCategoryStyle.cardBorder,
              ),
              boxShadow: _hovered ? AppShadows.lg : null,
            ),
            child: Row(
              children: [
                _TaskIcon(category: widget.task.category),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.task.courseLabel,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          fontSize: 12,
                          fontWeight: AppFonts.regular,
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          height: 1.25,
                        ),
                      ),
                      Text(
                        widget.task.unitTitle,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          fontSize: 14,
                          fontWeight: AppFonts.medium,
                          color: AppColors.primary,
                          height: 1.25,
                        ),
                      ),
                      if (widget.task.subtitle != null)
                        Text(
                          widget.task.subtitle!,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.custom(
                            fontSize: 12,
                            fontWeight: AppFonts.regular,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            height: 1.25,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: _hovered ? const Offset(-0.25, 0) : Offset.zero,
                  child: LucideChevronLeftIcon(
                    size: 16,
                    color: style.accentText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({required this.category});

  final IncompleteTaskCategory category;

  @override
  Widget build(BuildContext context) {
    final style = IncompleteCategoryStyle.forCategory(category);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: style.iconBackground,
        borderRadius: AppRadius.borderTailwindXl,
      ),
      alignment: Alignment.center,
      child: IncompleteTaskIcons.cardIcon(category),
    );
  }
}
