import '../../../core/theme/app_spacing.dart';

class RankingTableMetrics {
  const RankingTableMetrics({
    required this.tablePadding,
    required this.rowPaddingX,
    required this.rowPaddingY,
    required this.headerPaddingY,
    required this.gridGap,
    required this.rankCol,
    required this.pointsCol,
    required this.avatarSize,
    required this.bodyFontSize,
    required this.headerFontSize,
    required this.pointsBadgeMinWidth,
    required this.pointsBadgeHeight,
  });

  final double tablePadding;
  final double rowPaddingX;
  final double rowPaddingY;
  final double headerPaddingY;
  final double gridGap;

  final double rankCol;

  final double pointsCol;

  final double avatarSize;
  final double bodyFontSize;
  final double headerFontSize;
  final double pointsBadgeMinWidth;
  final double pointsBadgeHeight;

  factory RankingTableMetrics.forWidth(double width) {
    final compact = width < 600;

    if (compact) {
      return const RankingTableMetrics(
        tablePadding: AppSpacing.base,
        rowPaddingX: AppSpacing.base,
        rowPaddingY: AppSpacing.md,
        headerPaddingY: AppSpacing.md,
        gridGap: AppSpacing.md,
        rankCol: 52,
        pointsCol: 88,
        avatarSize: 40,
        bodyFontSize: 12,
        headerFontSize: 12,
        pointsBadgeMinWidth: 44,
        pointsBadgeHeight: 26,
      );
    }

    return const RankingTableMetrics(
      tablePadding: AppSpacing.rankingTablePadding,
      rowPaddingX: AppSpacing.rankingRowPaddingX,
      rowPaddingY: AppSpacing.rankingRowPaddingY,
      headerPaddingY: AppSpacing.md,
      gridGap: AppSpacing.rankingGridGap,
      rankCol: AppSpacing.rankingRankCol,
      pointsCol: AppSpacing.rankingPointsCol,
      avatarSize: AppSpacing.rankingAvatarCol,
      bodyFontSize: 14,
      headerFontSize: 14,
      pointsBadgeMinWidth: 48,
      pointsBadgeHeight: 28,
    );
  }
}
