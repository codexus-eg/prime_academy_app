class CourseRankEntry {
  const CourseRankEntry({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.points,
    required this.rank,
    this.imageUrl,
  });

  final int id;
  final String firstname;
  final String lastname;
  final int points;
  final int rank;
  final String? imageUrl;

  String get fullName {
    final name = '$firstname $lastname'.trim();
    return name.isEmpty ? '—' : name;
  }

  factory CourseRankEntry.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    final nestedUrl =
        image is Map<String, dynamic> ? image['url'] as String? : null;

    return CourseRankEntry(
      id: _asInt(json['id']),
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      points: _asInt(json['points']),
      rank: _asInt(json['rank']),
      imageUrl: json['image_url'] as String? ?? nestedUrl,
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
