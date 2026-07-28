import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class SessionBlockedPage extends StatelessWidget {
  const SessionBlockedPage({super.key});

  static const routePath = '/session-blocked';
  static const routeName = 'session-blocked';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1217),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageContentHorizontalPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconCluster(
                ringColor: AppColors.blue.withValues(alpha: 0.2),
                icon: Icons.shield_outlined,
                iconColor: AppColors.blue,
                badgeIcon: Icons.devices_outlined,
              ),
              const SizedBox(height: AppSpacing.massive),
              Text(
                'الجلسة محجوزة',
                style: AppTypography.size28.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 1,
                color: AppColors.blue.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'هذا الحساب مفتوح حالياً على جهاز آخر. لا يمكن فتح نفس الحساب على أكثر من جهاز في وقت واحد.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onDark.withValues(alpha: 0.45),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _InfoCard(
                icon: Icons.devices_outlined,
                title: 'ماذا تفعل؟',
                body:
                    'أغلق الجلسة على الجهاز الآخر أو انتظر حتى تنتهي تلقائياً، ثم حاول مرة أخرى.',
                accent: AppColors.blue,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home/courses');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderCard,
                    ),
                  ),
                  child: const Text('العودة للخلف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionErrorPage extends StatelessWidget {
  const SessionErrorPage({super.key});

  static const routePath = '/session-error';
  static const routeName = 'session-error';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1217),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageContentHorizontalPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconCluster(
                ringColor: AppColors.error.withValues(alpha: 0.2),
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.massive),
              Text(
                'تعذّر الاتصال بالخادم',
                style: AppTypography.size28.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 1,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'فشل الاتصال بعد عدة محاولات متكررة. تحقق من اتصالك بالإنترنت ثم حاول مجدداً.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onDark.withValues(alpha: 0.45),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _InfoCard(
                icon: Icons.wifi_off_rounded,
                title: 'ماذا تفعل؟',
                body:
                    'تأكد من اتصالك بالإنترنت، ثم اضغط على زر العودة وأعد تحميل الصفحة.',
                accent: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home/courses');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderCard,
                    ),
                  ),
                  child: const Text('العودة والمحاولة مجدداً'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCluster extends StatelessWidget {
  const _IconCluster({
    required this.ringColor,
    required this.icon,
    required this.iconColor,
    this.badgeIcon,
  });

  final Color ringColor;
  final IconData icon;
  final Color iconColor;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF161C29),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Icon(icon, size: 34, color: iconColor),
          ),
          if (badgeIcon != null)
            Positioned(
              bottom: 24,
              left: 24,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF161C29),
                  border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                ),
                child: Icon(badgeIcon, size: 13, color: iconColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: const Color(0xFF12161F),
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onDark.withValues(alpha: 0.7),
                    fontWeight: AppFonts.semibold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onDark.withValues(alpha: 0.35),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
