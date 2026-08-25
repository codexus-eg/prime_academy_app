import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Web `asideDesign` chrome: `bg-aside-bg rounded-t-3xl overflow-hidden pb-8 shadow-lg`.
class LessonAsideShell extends StatelessWidget {
  const LessonAsideShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.tailwind3xl),
        ),
        boxShadow: AppShadows.tailwindLg,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.tailwind3xl),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.lessonAsideBottomPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Web `ChatHeader` / `FilesSection` header: 150px gradient, `text-3xl font-semibold`,
/// close `absolute top-2 left-2 text-2xl text-white/50`.
class LessonAsideTitleHeader extends StatefulWidget {
  const LessonAsideTitleHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  State<LessonAsideTitleHeader> createState() => _LessonAsideTitleHeaderState();
}

class _LessonAsideTitleHeaderState extends State<LessonAsideTitleHeader> {
  var _closeHovered = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.lessonChatFilesHeaderHeight,
      width: double.infinity,
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.lessonChatFilesHeader,
            ),
            child: SizedBox.expand(),
          ),
          Center(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.size30.copyWith(
                color: AppColors.onDark,
                fontWeight: AppFonts.semibold,
              ),
            ),
          ),
          if (widget.onClose != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _closeHovered = true),
                onExit: (_) => setState(() => _closeHovered = false),
                child: GestureDetector(
                  onTap: widget.onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.white.withValues(
                        alpha: _closeHovered ? 1 : 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
