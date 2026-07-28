class StudentAwardLevel {
  const StudentAwardLevel({
    required this.id,
    required this.title,
    required this.questionsRequired,
    required this.imageIndex,
  });

  final int id;
  final String title;
  final int questionsRequired;
  final int imageIndex;

  factory StudentAwardLevel.fromJson(Map<String, dynamic> json) {
    final levelRaw = json['level'];
    final level = levelRaw is Map<String, dynamic> ? levelRaw : json;

    return StudentAwardLevel(
      id: _asInt(json['id']),
      title: level['title'] as String? ?? '',
      questionsRequired: _asInt(level['questionsRequired']),
      imageIndex: _asInt(level['imageIndex']),
    );
  }
}

class StudentAwardCertificate {
  const StudentAwardCertificate({
    required this.id,
    required this.type,
    required this.templateIndex,
    required this.referenceId,
    required this.studentName,
    required this.teacherName,
  });

  final int id;
  final String type;
  final int templateIndex;
  final String referenceId;
  final String studentName;
  final String teacherName;

  factory StudentAwardCertificate.fromJson(Map<String, dynamic> json) {
    return StudentAwardCertificate(
      id: _asInt(json['id']),
      type: json['type'] as String? ?? '',
      templateIndex: _asInt(json['template_index']),
      referenceId: (json['reference_id'] ?? '').toString(),
      studentName: json['student_name'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? '',
    );
  }
}

class StudentAwards {
  const StudentAwards({
    this.certificates = const [],
    this.studentClassificationLevels = const [],
  });

  final List<StudentAwardCertificate> certificates;
  final List<StudentAwardLevel> studentClassificationLevels;

  bool get hasAwards =>
      certificates.isNotEmpty || studentClassificationLevels.isNotEmpty;

  factory StudentAwards.fromJson(Map<String, dynamic> json) {
    final certsJson = json['certificates'];
    final levelsJson = json['studentClassificationLevels'];

    final certificates = certsJson is List
        ? certsJson
            .whereType<Map<String, dynamic>>()
            .map(StudentAwardCertificate.fromJson)
            .toList()
        : <StudentAwardCertificate>[];

    final levels = levelsJson is List
        ? levelsJson
            .whereType<Map<String, dynamic>>()
            .map(StudentAwardLevel.fromJson)
            .toList()
        : <StudentAwardLevel>[];

    return StudentAwards(
      certificates: certificates,
      studentClassificationLevels: levels,
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
