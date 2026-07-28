import 'package:flutter/material.dart';

import '../../theme/app_module_overlays.dart';
import '../../theme/app_theme.dart';

class CourseModuleSurface extends StatelessWidget {
  const CourseModuleSurface({
    super.key,
    required this.overlay,
    required this.child,
  });

  final CourseModuleOverlay overlay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderCard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: ColoredBox(color: AppTheme.courseModuleSurface),
              ),
              AppModuleOverlays.glow(overlay: overlay, width: width),

              child,
            ],
          );
        },
      ),
    );
  }
}
