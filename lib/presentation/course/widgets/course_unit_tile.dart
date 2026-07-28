import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_module_overlays.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surfaces/course_module_surface.dart';
import '../models/course_unit.dart';
import 'lesson_timeline.dart';

const _kOliveIconAsset = 'assets/icons/olive.png';

class CourseUnitTile extends StatelessWidget {
  const CourseUnitTile({
    super.key,
    required this.courseId,
    required this.unit,
    required this.isExpanded,
    required this.onTap,
  });

  final String courseId;
  final CourseUnit unit;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overlay = unit.resolvedOverlay;

    return CourseModuleSurface(
      overlay: overlay,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.courseTitleInner),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ModuleHeaderBody(unit: unit),
                  ),
                  const SizedBox(width: AppSpacing.courseModuleTriggerGap),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppDurations.unitExpand,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.onDark,
                      size: AppSpacing.base,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.unitExpand,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded && unit.lessons.isNotEmpty
                ? LessonTimeline(
                    courseId: courseId,
                    unitId: unit.id,
                    lessons: unit.lessons,
                    dotColor: AppModuleOverlays.timelineDotFor(overlay),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ModuleHeaderBody extends StatelessWidget {
  const _ModuleHeaderBody({required this.unit});

  final CourseUnit unit;

  @override
  Widget build(BuildContext context) {
    if (!unit.special) {
      return Text(
        unit.title,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.headingModuleTitle,
      );
    }

    final iconSize = MediaQuery.sizeOf(context).width >= AppSpacing.breakpointMd
        ? AppSpacing.courseModuleOliveIconLg
        : AppSpacing.courseModuleOliveIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              _kOliveIconAsset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppSpacing.courseModuleHeaderInnerGap),
            Expanded(
              child: Text(
                unit.title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headingModuleTitle,
              ),
            ),
          ],
        ),
        if (unit.description != null) ...[
          const SizedBox(height: AppSpacing.courseModuleHeaderInnerGap),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: AppSpacing.courseModuleDescriptionWidthFactor,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                unit.description!,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headingModuleDescription,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
