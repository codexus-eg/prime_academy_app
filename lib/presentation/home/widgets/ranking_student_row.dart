import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/ranking_student.dart';
import 'ranking_icons.dart';
import 'ranking_table_metrics.dart';
import 'ranking_trophy_icon.dart';

class RankingStudentRow extends StatefulWidget {
  const RankingStudentRow({
    super.key,
    required this.student,
    required this.metrics,
  });

  final RankingStudent student;
  final RankingTableMetrics metrics;

  @override
  State<RankingStudentRow> createState() => _RankingStudentRowState();
}

class _RankingStudentRowState extends State<RankingStudentRow> {
  bool _hovered = false;

  RankingStudent get student => widget.student;
  RankingTableMetrics get metrics => widget.metrics;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: student.isCurrentStudent
              ? AppGradients.rankingCurrentRow
              : null,
          color: _hovered && !student.isCurrentStudent
              ? (student.rank <= 3
                  ? AppColors.overlayWhite3
                  : AppColors.overlayWhite2)
              : null,
          border: const Border(
            bottom: BorderSide(color: AppColors.overlayWhite3),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: metrics.rowPaddingX,
            vertical: metrics.rowPaddingY,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(
                width: metrics.avatarSize,
                child: Center(
                  child: _StudentAvatar(
                    student: student,
                    size: metrics.avatarSize,
                  ),
                ),
              ),
              SizedBox(width: metrics.gridGap),
              SizedBox(
                width: metrics.rankCol,
                child: Center(
                  child: _RankBadge(
                    rank: student.rank,
                    fontSize: metrics.bodyFontSize,
                  ),
                ),
              ),
              SizedBox(width: metrics.gridGap),
              Expanded(
                child: _StudentName(
                  name: student.name,
                  isCurrentStudent: student.isCurrentStudent,
                  fontSize: metrics.bodyFontSize,
                ),
              ),
              SizedBox(width: metrics.gridGap),
              SizedBox(
                width: metrics.pointsCol,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PointsBadge(
                      points: student.points,
                      rank: student.rank,
                      metrics: metrics,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    RankingTrophyIcon(rank: student.rank),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({
    required this.student,
    required this.size,
  });

  final RankingStudent student;
  final double size;

  Color _borderColor() => switch (student.rank) {
        1 => AppColors.rankGold,
        2 => AppColors.rankSilver,
        3 => AppColors.rankBronzeDark,
        _ => AppColors.blue,
      };

  List<BoxShadow>? _shadow() => switch (student.rank) {
        1 => [
            BoxShadow(
              color: AppColors.rankGold.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        2 => [
            BoxShadow(
              color: AppColors.rankSilver.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        3 => [
            BoxShadow(
              color: AppColors.rankBronzeDark.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor(), width: 2),
        boxShadow: _shadow(),
      ),
      child: ClipOval(
        child: _buildAvatarContent(size),
      ),
    );
  }

  Widget _buildAvatarContent(double size) {
    final networkUrl = student.avatarUrl;
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _placeholder(size),
      );
    }

    if (student.avatarAsset != null) {
      return Image.asset(
        student.avatarAsset!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }

    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return ColoredBox(
      color: AppColors.mainBg3,
      child: Center(
        child: RankingIcons.svg(
          RankingIcons.studentFill,
          size: size * 0.55,
          color: AppColors.blue.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _StudentName extends StatelessWidget {
  const _StudentName({
    required this.name,
    required this.isCurrentStudent,
    required this.fontSize,
  });

  final String name;
  final bool isCurrentStudent;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: AppTypography.bodyMd.copyWith(
              color: isCurrentStudent
                  ? AppColors.accentSoft
                  : AppColors.onDark,
              fontWeight:
                  isCurrentStudent ? AppFonts.semibold : AppFonts.regular,
              fontSize: fontSize,
            ),
          ),
        ),
        if (isCurrentStudent) ...[
          const SizedBox(width: AppSpacing.sm),
          const _YouBadge(),
        ],
      ],
    );
  }
}

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.rankBlueGlow20,
        borderRadius: BorderRadius.circular(AppRadius.tailwind3xl),
      ),
      child: Text(
        'أنت',
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.blueLight,
          fontWeight: AppFonts.regular,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({
    required this.points,
    required this.rank,
    required this.metrics,
  });

  final int points;
  final int rank;
  final RankingTableMetrics metrics;

  bool get _isTopThree => rank <= 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: metrics.pointsBadgeMinWidth,
        minHeight: metrics.pointsBadgeHeight,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: _isTopThree ? AppGradients.rankingPointsCurrent : null,
        color: _isTopThree ? null : AppColors.rankBlueGlow20,
        borderRadius: AppRadius.borderTabCell,
        boxShadow: _isTopThree ? AppShadows.sm : null,
      ),
      child: Text(
        '$points',
        style: AppTypography.bodyMd.copyWith(
          color: _isTopThree ? AppColors.onDark : AppColors.blueLight,
          fontWeight: AppFonts.bold,
          fontSize: metrics.bodyFontSize,
        ),
      ),
    );
  }
}

class _RankBadge extends StatefulWidget {
  const _RankBadge({
    required this.rank,
    required this.fontSize,
  });

  final int rank;
  final double fontSize;

  @override
  State<_RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<_RankBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.rank == 1
        ? AppSpacing.rankingRankBadgeSizeLg
        : AppSpacing.rankingRankBadgeSize;
    final style = _badgeStyle(widget.rank);

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: style.gradient,
          color: style.fillColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.overlayWhite10, width: 2),
          boxShadow: style.shadow,
        ),
        child: Text(
          '${widget.rank}',
          style: AppTypography.bodyMd.copyWith(
            color: style.textColor,
            fontWeight: AppFonts.bold,
            fontSize: widget.fontSize,
          ),
        ),
      ),
    );
  }
}

class _RankBadgeStyle {
  const _RankBadgeStyle({
    this.gradient,
    this.fillColor,
    required this.textColor,
    this.shadow,
  });

  final LinearGradient? gradient;
  final Color? fillColor;
  final Color textColor;
  final List<BoxShadow>? shadow;
}

_RankBadgeStyle _badgeStyle(int rank) => switch (rank) {
      1 => _RankBadgeStyle(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.rankGold, AppColors.rankGoldDeep],
          ),
          textColor: AppColors.lessonStatusRing,
          shadow: [
            BoxShadow(
              color: AppColors.rankGold.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      2 => _RankBadgeStyle(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.rankSilverLight, AppColors.rankSilver],
          ),
          textColor: AppColors.lessonStatusRing,
          shadow: [
            BoxShadow(
              color: AppColors.rankSilver.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      3 => _RankBadgeStyle(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.rankBronzeDark, AppColors.rankBronzeDeep],
          ),
          textColor: AppColors.onDark,
          shadow: [
            BoxShadow(
              color: AppColors.rankBronzeDark.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      _ => _RankBadgeStyle(
          fillColor: AppColors.rankDefaultFill,
          textColor: AppColors.onDark,
        ),
    };
