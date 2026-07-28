import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'profile_avatar_uploader.dart';

class HomeProfileSection extends StatelessWidget {
  const HomeProfileSection({
    super.key,
    this.userName = '',
    this.avatarUrl,
    this.onAvatarUploaded,
  });

  final String userName;
  final String? avatarUrl;
  final Future<void> Function()? onAvatarUploaded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        AppSpacing.xl,
        AppSpacing.pageContentHorizontal,
        AppSpacing.lg,
      ),
      child: Row(
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
    );
  }
}
