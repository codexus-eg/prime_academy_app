import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/legal_urls.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class LegalPolicyLinks extends StatelessWidget {
  const LegalPolicyLinks({super.key});

  static Future<void> openPrivacyAndTerms() async {
    final uri = Uri.parse(LegalUrls.privacyAndTerms);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTypography.bodySm.copyWith(
      color: AppColors.secondaryOpaque,
      fontWeight: AppFonts.medium,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.secondaryOpaque,
    );
    final separatorStyle = AppTypography.bodySm.copyWith(
      color: AppColors.textMuted,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: openPrivacyAndTerms,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('الشروط والأحكام', style: linkStyle),
          ),
          Text('·', style: separatorStyle),
          TextButton(
            onPressed: openPrivacyAndTerms,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('سياسة الخصوصية', style: linkStyle),
          ),
        ],
      ),
    );
  }
}
