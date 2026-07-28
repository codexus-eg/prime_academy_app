import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class ExamReviewTypeBadge extends StatelessWidget {
  const ExamReviewTypeBadge({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final info = _typeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.background,

        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(color: info.color.withValues(alpha: 0.125)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 12, color: info.color),
          const SizedBox(width: 6),
          Text(
            info.label,
            style: AppTypography.badge.copyWith(
              color: info.color,
              fontWeight: AppFonts.medium,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeVisual {
  const _TypeVisual({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
}

_TypeVisual _typeInfo(String type) {
  return switch (type) {
    'mcq' => const _TypeVisual(
        icon: Icons.check_box_outlined,
        label: 'اختيار من متعدد',
        color: Color(0xFF2072E0),
        background: Color(0x1A2072E0),
      ),
    'essay' => const _TypeVisual(
        icon: Icons.notes_rounded,
        label: 'مقالي',
        color: Color(0xFF7B4FE0),
        background: Color(0x1A7B4FE0),
      ),
    'fill-blank' => const _TypeVisual(
        icon: Icons.edit_outlined,
        label: 'اكمل',
        color: Color(0xFF2BA5D9),
        background: Color(0x1A2BA5D9),
      ),
    'match' => const _TypeVisual(
        icon: Icons.link_rounded,
        label: 'توصيل',
        color: Color(0xFFFFCF24),
        background: Color(0x1AFFCF24),
      ),
    'passage' => const _TypeVisual(
        icon: Icons.subject_rounded,
        label: 'فقرة',
        color: Color(0xFF6A760C),
        background: Color(0x1A6A760C),
      ),
    're-order' => const _TypeVisual(
        icon: Icons.format_list_numbered_rounded,
        label: 'ترتيب',
        color: Color(0xFFEDB60A),
        background: Color(0x1AEDB60A),
      ),
    _ => const _TypeVisual(
        icon: Icons.help_outline_rounded,
        label: 'مجهول',
        color: Color(0xFF9AA0A7),
        background: Color(0x1A9AA0A7),
      ),
  };
}
