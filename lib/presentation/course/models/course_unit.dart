import '../../../core/theme/app_module_overlays.dart';
import 'course_lesson.dart';

class CourseUnit {
  const CourseUnit({
    required this.id,
    required this.title,
    this.overlay = CourseModuleOverlay.none,
    this.special = false,
    this.description,
    this.lessons = const [],
    this.progressPercent = 40,
  });

  final String id;
  final String title;
  final CourseModuleOverlay overlay;
  final bool special;
  final String? description;
  final List<CourseLesson> lessons;
  final int progressPercent;

  CourseModuleOverlay get resolvedOverlay =>
      special ? CourseModuleOverlay.olive : overlay;
}

class CourseDetail {
  const CourseDetail({
    required this.id,
    required this.title,
    required this.units,
    this.isEnrolled = false,
  });

  final String id;
  final String title;
  final List<CourseUnit> units;
  final bool isEnrolled;
}

