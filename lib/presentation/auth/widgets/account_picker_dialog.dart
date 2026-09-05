import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/config/cdn_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/auth/auth_models.dart';
import '../../home/widgets/profile_avatar_uploader.dart';

Future<int?> showAccountPickerDialog(
  BuildContext context, {
  required String title,
  String? description,
  required List<LinkedAccount> accounts,
  int? loadingAccountId,
}) {
  return showDialog<int>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => _AccountPickerDialog(
      title: title,
      description: description,
      accounts: accounts,
      loadingAccountId: loadingAccountId,
    ),
  );
}

class _AccountPickerDialog extends StatelessWidget {
  const _AccountPickerDialog({
    required this.title,
    required this.description,
    required this.accounts,
    this.loadingAccountId,
  });

  final String title;
  final String? description;
  final List<LinkedAccount> accounts;
  final int? loadingAccountId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.mainBg2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headingDialog.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: loadingAccountId == null
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onDark,
                    ),
                  ),
                ],
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.base),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final account in accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _AccountPickerTile(
                            account: account,
                            isLoading: loadingAccountId == account.id,
                            enabled: loadingAccountId == null,
                            onTap: () => Navigator.of(context).pop(account.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPickerTile extends StatelessWidget {
  const _AccountPickerTile({
    required this.account,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final LinkedAccount account;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = account.imageUrl;
    final resolvedImage = imageUrl == null || imageUrl.isEmpty
        ? null
        : CdnConfig.staticUrl(imageUrl);

    return Material(
      color: AppColors.mainBg3,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: AppColors.transparent,
            ),
          ),
          child: Row(
            children: [
              _AccountAvatar(resolvedImage: resolvedImage),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(
                  account.name,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onDark,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryOpaque,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({this.resolvedImage});

  final String? resolvedImage;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;

    if (resolvedImage == null || resolvedImage!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SvgPicture.asset(
          ProfileAvatarUploader.defaultAsset,
          colorFilter: const ColorFilter.mode(
            AppColors.secondaryOpaque,
            BlendMode.srcIn,
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        resolvedImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.mainBg,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SvgPicture.asset(
            ProfileAvatarUploader.defaultAsset,
            colorFilter: const ColorFilter.mode(
              AppColors.secondaryOpaque,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
