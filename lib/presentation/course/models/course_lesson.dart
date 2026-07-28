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
