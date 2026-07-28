import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class ExamGraduationBadge extends StatelessWidget {
  const ExamGraduationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1128),

          borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
          border: Border.all(color: AppColors.examAccentBlue, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.examAccentBlue.withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -0.785398,
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.examAccentBlue,
            size: 28,
          ),
        ),
      ),
    );
  }
}
