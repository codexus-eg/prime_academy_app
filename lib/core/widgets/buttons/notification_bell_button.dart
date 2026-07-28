import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../gradient_border.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.onTap,
    this.showDot = true,
  });

  final VoidCallback? onTap;
  final bool showDot;

  static const String assetPath = 'assets/images/icon_bell.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppSpacing.notificationBellOuterSize,
          height: AppSpacing.notificationBellOuterSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GradientBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                gradient: AppGradients.borderGradientDefault,
                backgroundColor: AppColors.surfaceElevated,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Image.asset(
                  assetPath,
                  width: AppSpacing.notificationBellIconWidth,
                  height: AppSpacing.notificationBellIconHeight,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              if (showDot)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: _BellNotificationDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellNotificationDot extends StatelessWidget {
  const _BellNotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.notificationBellDotSize,
      height: AppSpacing.notificationBellDotSize,
      decoration: const BoxDecoration(
        color: AppColors.notificationDot,
        shape: BoxShape.circle,
      ),
    );
  }
}
