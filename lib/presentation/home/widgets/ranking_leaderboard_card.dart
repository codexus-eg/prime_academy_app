import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/ranking_student.dart';
import 'ranking_student_row.dart';
import 'ranking_table_metrics.dart';

class RankingLeaderboardCard extends StatelessWidget {
  const RankingLeaderboardCard({
    super.key,
    required this.students,
    required this.currentPage,
    required this.totalPages,
    this.sortField = 'rank',
    this.sortAscending = true,
    this.onSort,
    this.onPrevious,
    this.onNext,
    this.emptyState,
    this.currentStudentKey,
  });

  final List<RankingStudent> students;
  final int currentPage;
  final int totalPages;
  final String sortField;
  final bool sortAscending;
  final ValueChanged<String>? onSort;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget? emptyState;
  final Key? currentStudentKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = RankingTableMetrics.forWidth(constraints.maxWidth);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(metrics.tablePadding),
          decoration: BoxDecoration(
            color: AppColors.mainBg3,
            borderRadius: AppRadius.borderRankingCard,
            border: Border.all(color: AppColors.overlayWhite3),
            boxShadow: AppShadows.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (totalPages > 1) ...[
                _PaginationBar(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPrevious: onPrevious,
                  onNext: onNext,
                ),
                const SizedBox(height: AppSpacing.base),
              ],
              _TableHeader(
                metrics: metrics,
                sortField: sortField,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              if (students.isEmpty)
                emptyState ?? const SizedBox.shrink()
              else
                ...students.map(
                  (student) => RankingStudentRow(
                    key: student.isCurrentStudent ? currentStudentKey : null,
                    student: student,
                    metrics: metrics,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentPage > 1;
    final canGoForward = currentPage < totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PaginationButton(
          label: 'السابق',
          onPressed: canGoBack ? onPrevious : null,
        ),
        const SizedBox(width: AppSpacing.base),
        Text(
          'صفحة $currentPage من $totalPages',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
        ),
        const SizedBox(width: AppSpacing.base),
        _PaginationButton(
          label: 'التالي',
          onPressed: canGoForward ? onNext : null,
        ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mainBg,
      borderRadius: AppRadius.borderAuthButton,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.borderAuthButton,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onDark,
              fontWeight: AppFonts.regular,
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.metrics,
    required this.sortField,
    required this.sortAscending,
    this.onSort,
  });

  final RankingTableMetrics metrics;
  final String sortField;
  final bool sortAscending;
  final ValueChanged<String>? onSort;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.overlayWhite6, width: 2),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: metrics.rowPaddingX,
          vertical: metrics.headerPaddingY,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            SizedBox(
              width: metrics.avatarSize,
              child: Center(
                child: Text(
                  '#',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    fontWeight: AppFonts.semibold,
                    fontSize: metrics.headerFontSize,
                  ),
                ),
              ),
            ),
            SizedBox(width: metrics.gridGap),
            SizedBox(
              width: metrics.rankCol,
              child: Center(
                child: _HeaderLabel(
                  label: 'الترتيب',
                  showSort: true,
                  active: sortField == 'rank',
                  ascending: sortAscending,
                  onTap: onSort == null ? null : () => onSort!('rank'),
                  fontSize: metrics.headerFontSize,
                ),
              ),
            ),
            SizedBox(width: metrics.gridGap),
            Expanded(
              child: _HeaderLabel(
                label: 'الاسم',
                showSort: true,
                active: sortField == 'name',
                ascending: sortAscending,
                onTap: onSort == null ? null : () => onSort!('name'),
                fontSize: metrics.headerFontSize,
              ),
            ),
            SizedBox(width: metrics.gridGap),
            SizedBox(width: metrics.pointsCol),
          ],
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({
    required this.label,
    this.showSort = false,
    this.active = false,
    this.ascending = true,
    this.onTap,
    required this.fontSize,
  });

  final String label;
  final bool showSort;
  final bool active;
  final bool ascending;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          label == 'الترتيب' ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: active ? AppColors.blueLight : AppColors.textMuted.withValues(
              alpha: 0.6,
            ),
            fontWeight: AppFonts.semibold,
            fontSize: fontSize,
          ),
        ),
        if (showSort) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            active
                ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.arrow_upward,
            size: fontSize,
            color: active
                ? AppColors.blueLight
                : AppColors.tabInactive.withValues(alpha: 0.4),
          ),
        ],
      ],
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}
