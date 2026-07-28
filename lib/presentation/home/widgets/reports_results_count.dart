import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ReportsResultsCount extends StatefulWidget {
  const ReportsResultsCount({super.key, required this.count});

  final int count;

  @override
  State<ReportsResultsCount> createState() => _ReportsResultsCountState();
}

class _ReportsResultsCountState extends State<ReportsResultsCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _pulse,
          child: Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${widget.count} نتيجة',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
