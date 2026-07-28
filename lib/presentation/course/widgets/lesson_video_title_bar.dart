import 'package:flutter/material.dart';

import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class LessonVideoTitleBar extends StatelessWidget {
  const LessonVideoTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(
                child: ColoredBox(color: AppTheme.courseModuleSurface),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * 0.7,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.courseTitle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: AppTypography.headingModuleTitle.copyWith(
                      fontSize: 20,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
