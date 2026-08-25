import '../../../core/theme/app_module_overlays.dart';
import '../../../data/courses/user_course.dart';
import 'course_lesson.dart';
import 'course_unit.dart';

abstract final class CourseDetailMapper {
  static CourseDetail fromUserCourse(UserCourse course) {
    return CourseDetail(
      id: '${course.id}',
      title: course.title,
      isEnrolled: course.isEnrolled,
      units: [
        for (final module in course.modules) _mapModule(course, module),
      ],
    );
  }

  static CourseUnit _mapModule(UserCourse course, UserCourseModule module) {
    return CourseUnit(
      id: '${module.id}',
      title: module.title,
      overlay: _overlayFor(module.color),
      special: module.special,
      description: module.description,
      lessons: lessonsFromItems(course.isEnrolled, module.items),
    );
  }

  static List<CourseLesson> lessonsFromItems(
    bool isEnrolled,
    List<UserModuleItem> items,
  ) {
    return [
      for (final item in items)
        if (_visible(item)) _mapItem(isEnrolled, item),
    ];
  }

  static bool _visible(UserModuleItem item) {
    switch (item.type) {
      case ModuleItemType.lesson:
        return (item.lesson?.title ?? '').isNotEmpty;
      case ModuleItemType.externalSource:
        return (item.externalSource?.title ?? '').isNotEmpty;
      case ModuleItemType.quiz:
        return true;
      case ModuleItemType.unknown:
        return false;
    }
  }

  static CourseLesson _mapItem(bool isEnrolled, UserModuleItem item) {
    switch (item.type) {
      case ModuleItemType.quiz:
        return CourseLesson(
          id: '${item.quiz?.id ?? item.id}',
          title: 'مستعد للأختبار ؟',
          status: LessonStatus.inProgress,
          isChallenge: true,
        );

      case ModuleItemType.externalSource:
        final external = item.externalSource!;
        return CourseLesson(
          id: '${item.id}',
          title: external.title,
          status: LessonStatus.notStarted,
          isExternal: true,
          externalUrl: external.url,
          locked: !isEnrolled || external.url == null,
        );

      case ModuleItemType.lesson:
      case ModuleItemType.unknown:
        final lesson = item.lesson!;
        final canAccess = isEnrolled || lesson.accessWithoutEnrollment;
        final percent = _progressPercent(isEnrolled, lesson);

        return CourseLesson(

          id: '${item.id}',
          title: lesson.title,
          status: _statusFor(isEnrolled, lesson, percent),
          duration: _formatDuration(lesson.videoLength),
          progressPercent: percent,
          hasTrophy: lesson.hasTrophy,
          videoUrl: lesson.externalUrl,
          locked: !canAccess,
        );
    }
  }

  static int _progressPercent(bool isEnrolled, UserModuleLesson lesson) {
    if (!isEnrolled) return 0;
    final duration = lesson.duration ?? 0;
    final position = lesson.lastPosition ?? 0;
    if (duration == 0) return 0;
    final pct = (position / duration) * 100;
    return pct.clamp(0, 100).round();
  }

  static LessonStatus _statusFor(
    bool isEnrolled,
    UserModuleLesson lesson,
    int percent,
  ) {
    if (lesson.watched) return LessonStatus.completed;
    if (isEnrolled && percent > 0) return LessonStatus.inProgress;
    return LessonStatus.notStarted;
  }

  static String? _formatDuration(int seconds) {
    if (seconds <= 0) return null;
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (hrs > 0) return '${two(hrs)}:${two(mins)}:${two(secs)}';
    return '${two(mins)}:${two(secs)}';
  }

  static CourseModuleOverlay _overlayFor(String color) {
    switch (color) {
      case 'BLUE':
        return CourseModuleOverlay.blue;
      case 'PURPLE':
        return CourseModuleOverlay.purple;
      case 'YELLOW':
        return CourseModuleOverlay.yellow;
      case 'CYAN':
        return CourseModuleOverlay.cyan;
      case 'GREEN':
        return CourseModuleOverlay.green;
      case 'OLIVE':
        return CourseModuleOverlay.olive;
      default:
        return CourseModuleOverlay.none;
    }
  }
}
