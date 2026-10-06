import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../course_materials_page.dart';
import 'lesson_action_icons.dart';

/// Web `Course.tsx` memo buttons — icon above label (`/assets/icons/file.svg`).
class CourseMemoButtons extends StatelessWidget {
  const CourseMemoButtons({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _MemoButton(
            label: 'المذكره المحلوله',
            onTap: () => context.push(
              CourseMaterialsPage.pathFor(courseId, solved: true),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MemoButton(
            label: 'المذكره الغير محلوله',
            onTap: () => context.push(
              CourseMaterialsPage.pathFor(courseId, solved: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoButton extends StatefulWidget {
  const _MemoButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_MemoButton> createState() => _MemoButtonState();
}

class _MemoButtonState extends State<_MemoButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.borderCard,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: AppColors.mainBg3,
              borderRadius: AppRadius.borderCard,
              border: Border.all(
                width: 2,
                color: _hovered ? AppColors.blue : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.only(
              top: AppSpacing.xsPlus,
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Web: <img class="h-6 w-6" src="/assets/icons/file.svg" />
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    LessonActionIcons.file,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    placeholderBuilder: (_) => const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 24,
                      color: AppColors.onDark,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onDark,
                    fontWeight: AppFonts.semibold,
                    height: 1.3,
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
