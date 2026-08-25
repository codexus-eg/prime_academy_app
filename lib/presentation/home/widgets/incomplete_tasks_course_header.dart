import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class IncompleteTasksCourseHeader extends StatelessWidget {
  const IncompleteTasksCourseHeader({
    super.key,
    required this.courseLabel,
    required this.taskCount,
    this.onCourseTap,
  });

  final String courseLabel;
  final int taskCount;
  final void Function(BuildContext triggerContext)? onCourseTap;

  static const double _rowHeight = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _CourseSelectTrigger(
              label: courseLabel,
              onTap: onCourseTap,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (taskCount > 0) _TaskCountBadge(count: taskCount),
        ],
      ),
    );
  }
}

class _CourseSelectTrigger extends StatefulWidget {
  const _CourseSelectTrigger({
    required this.label,
    this.onTap,
  });

  final String label;
  final void Function(BuildContext triggerContext)? onTap;

  @override
  State<_CourseSelectTrigger> createState() => _CourseSelectTriggerState();
}

class _CourseSelectTriggerState extends State<_CourseSelectTrigger> {
  bool _hovered = false;
  bool _focused = false;

  Color get _borderColor {
    if (_focused) return AppColors.reportBlueBorder;
    if (_hovered) return AppColors.rankBlueBorder30;
    return AppColors.overlayWhite6;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap == null
                ? null
                : () => widget.onTap!(context),
            borderRadius: AppRadius.borderRankingCard,
            child: Ink(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.mainBg3,
                borderRadius: AppRadius.borderRankingCard,
                border: Border.all(color: _borderColor),
                boxShadow: AppShadows.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onDark,
                        fontWeight: AppFonts.regular,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.tabInactive,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCountBadge extends StatelessWidget {
  const _TaskCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.incompleteTaskCountBadge,
        borderRadius: AppRadius.borderRankingCard,
        border: Border.all(color: AppColors.rankBlueGlow20),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.base),
        child: Center(
          child: Text(
            '$count مهمة',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.reportBlueText,
              fontWeight: AppFonts.semibold,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
