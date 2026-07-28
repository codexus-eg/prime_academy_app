class RankingStudent {
  const RankingStudent({
    required this.rank,
    required this.name,
    required this.points,
    this.avatarAsset,
    this.avatarUrl,
    this.showPlaceholderAvatar = false,
    this.isCurrentStudent = false,
  });

  final int rank;
  final String name;
  final int points;
  final String? avatarAsset;
  final String? avatarUrl;
  final bool showPlaceholderAvatar;
  final bool isCurrentStudent;
}
