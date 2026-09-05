import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'profile_avatar_uploader.dart';

class HomeProfileSection extends StatelessWidget {
  const HomeProfileSection({
    super.key,
    this.userName = '',
    this.avatarUrl,
    this.onAvatarUploaded,
    this.showSwitchAccount = false,
    this.onSwitchAccount,
  });

  final String userName;
  final String? avatarUrl;
  final Future<void> Function()? onAvatarUploaded;
  final bool showSwitchAccount;
  final VoidCallback? onSwitchAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        AppSpacing.xl,
        AppSpacing.pageContentHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProfileAvatarUploader(
                avatarUrl: avatarUrl,
                onUploaded: onAvatarUploaded,
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحبا', style: AppTypography.greeting),
                    Text(
                      userName.isEmpty ? '...' : userName,
                      style: AppTypography.headingProfileName,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showSwitchAccount) ...[
            const SizedBox(height: AppSpacing.base),
            _SwitchAccountButton(onPressed: onSwitchAccount),
          ],
        ],
      ),
    );
  }
}

class _SwitchAccountButton extends StatelessWidget {
  const _SwitchAccountButton({this.onPressed});

  static const _iconAsset = 'assets/icons/profile/switch_camera.svg';

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.borderShadcnLg,
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: AppGradients.switchAccountButton,
                borderRadius: AppRadius.borderShadcnLg,
                boxShadow: AppShadows.tailwindLg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تبديل الحساب',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SvgPicture.asset(
                    _iconAsset,
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    fit: BoxFit.contain,
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
