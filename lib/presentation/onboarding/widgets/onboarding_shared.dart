import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/custom_button.dart';
import '../../../core/widgets/buttons/premium_interactive_surface.dart';
import '../../../core/widgets/gradient_border.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.headerBorder, width: 1.1),
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/logo_prime.png',
          width: 128,
          height: 64,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class OnboardingCaptionBar extends StatelessWidget {
  const OnboardingCaptionBar({
    super.key,
    required this.text,
    this.fontSize = 20,
    this.fontWeight = AppFonts.bold,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderTailwindXl,
        boxShadow: AppShadows.buttonRest,
      ),
      child: GradientBorder(
        borderRadius: AppRadius.borderTailwindXl,
        backgroundColor: AppColors.surfaceElevated,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.heroButtonVerticalPadding,
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: AppTypography.buttonXl.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: AppColors.onDark,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: index == 0 ? 0 : AppSpacing.sm,
          ),
          child: AnimatedContainer(
            duration: AppDurations.onboardingIndicator,
            width: isActive ? AppSpacing.xxl : AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              color: isActive ? null : AppColors.cyan,
              gradient: isActive
                  ? AppGradients.onboardingAccent
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class OnboardingActions extends StatelessWidget {
  const OnboardingActions({
    super.key,
    required this.onNext,
    required this.onSkip,
    this.nextLabel = 'التالي',
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        0,
        AppSpacing.pageContentHorizontal,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          CustomButton.primary(
            onPressed: onNext,
            label: nextLabel,
            height: 60,
            borderRadius: AppRadius.borderReportChip,
            gradient: AppGradients.onboardingAccent,
            textStyle: AppTypography.buttonXl.copyWith(
              fontWeight: AppFonts.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          PremiumInteractiveSurface(
            onTap: onSkip,
            borderRadius: AppRadius.borderAnswerButton,
            accentColor: AppColors.cyan,
            child: Container(
              width: double.infinity,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.onboardingCaptionFill,
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                'تخطي',
                style: AppTypography.headingDialog.copyWith(
                  fontWeight: AppFonts.semibold,
                  height: 1.56,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
