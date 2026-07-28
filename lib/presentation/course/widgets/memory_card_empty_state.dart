import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class MemoryCardEmptyState extends StatelessWidget {
  const MemoryCardEmptyState({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: const Color(0x142196C4),
              borderRadius: BorderRadius.circular(AppRadius.tailwind2xl),
              border: Border.all(color: const Color(0x2E2196C4)),
              boxShadow: const [
                BoxShadow(color: Color(0x142196C4), blurRadius: 32),
              ],
            ),
            child: const Icon(
              Icons.style_rounded,
              size: 64,
              color: Color(0xFF2196C4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'لا توجد كروت حفظ',
            style: AppTypography.size20.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: AppFonts.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لم يتم إضافة كروت حفظ لهذا الدرس بعد',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.5),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.smPlus,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'العودة إلى الدرس',
              style: AppTypography.bodyMd.copyWith(
                fontWeight: AppFonts.semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
