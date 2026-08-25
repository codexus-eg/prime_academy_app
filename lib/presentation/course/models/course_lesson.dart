enum LessonStatus {
  completed,
  inProgress,
  notStarted,
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    required this.status,
    this.videoUrl,
    this.progressPercent = 0,
    this.duration,
    this.isChallenge = false,
    this.hasTrophy = false,
    this.isExternal = false,
    this.externalUrl,
    this.locked = false,
  });

  final String id;
  final String title;
  final LessonStatus status;

  final String? videoUrl;
  final int progressPercent;

  final String? duration;

  final bool isChallenge;

  final bool hasTrophy;

  final bool isExternal;
  final String? externalUrl;

  final bool locked;

  bool get isLessonItem => !isChallenge && !isExternal;

  CourseLesson copyWith({
    String? id,
    String? title,
    LessonStatus? status,
    String? videoUrl,
    int? progressPercent,
    String? duration,
    bool? isChallenge,
    bool? hasTrophy,
    bool? isExternal,
    String? externalUrl,
    bool? locked,
  }) {
    return CourseLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      progressPercent: progressPercent ?? this.progressPercent,
      duration: duration ?? this.duration,
      isChallenge: isChallenge ?? this.isChallenge,
      hasTrophy: hasTrophy ?? this.hasTrophy,
      isExternal: isExternal ?? this.isExternal,
      externalUrl: externalUrl ?? this.externalUrl,
      locked: locked ?? this.locked,
    );
  }
}

class LessonContext {
  const LessonContext({
    required this.courseId,
    required this.courseTitle,
    required this.unitId,
    required this.unitTitle,
    required this.lesson,
    required this.unitLessons,
    required this.unitProgressPercent,
  });

  final String courseId;
  final String courseTitle;
  final String unitId;
  final String unitTitle;
  final CourseLesson lesson;
  final List<CourseLesson> unitLessons;
  final int unitProgressPercent;
}
