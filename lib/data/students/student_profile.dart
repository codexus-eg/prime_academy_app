class StudentCourse {
  const StudentCourse({
    required this.id,
    required this.title,
    required this.type,
  });

  final int id;
  final String title;
  final String? type;

  factory StudentCourse.fromJson(Map<String, dynamic> json) {
    return StudentCourse(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      title: json['title'] as String? ?? '',
      type: json['type'] as String?,
    );
  }
}

class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.courses,
    required this.hasIncomplete,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final List<StudentCourse> courses;
  final bool hasIncomplete;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final coursesJson = json['courses'];
    final courses = coursesJson is List
        ? coursesJson
            .whereType<Map<String, dynamic>>()
            .map(StudentCourse.fromJson)
            .toList()
        : <StudentCourse>[];

    final image = json['image'];
    final nestedUrl =
        image is Map<String, dynamic> ? image['url'] as String? : null;

    return StudentProfile(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      name: _parseStudentName(json),
      imageUrl: json['image_url'] as String? ?? nestedUrl,
      courses: courses,
      hasIncomplete: json['hasIncomplete'] == true,
    );
  }
}

String _parseStudentName(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  if (name != null && name.trim().isNotEmpty) return name.trim();

  final first = (json['firstname'] as String? ?? '').trim();
  final last = (json['lastname'] as String? ?? '').trim();
  if (first.isEmpty && last.isEmpty) return '';
  return '$first $last'.trim();
}
