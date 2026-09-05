import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/onboarding_assets.dart';
import 'onboarding_visual.dart';
import 'onboarding_shared.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.data,
    required this.isActive,
  });

  final OnboardingSlideData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        AppSpacing.lg,
        AppSpacing.pageContentHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OnboardingCaptionBar(
              text: data.title,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.subtitle,
            textAlign: TextAlign.right,
            style: AppTypography.custom(
              fontSize: 24,
              fontWeight: AppFonts.semibold,
              color: AppColors.onDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ClipRect(
              child: OnboardingVisual(
                asset: data.visualAsset,
                isActive: isActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
