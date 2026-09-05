import 'user_course.dart';

/// In-memory cache mirroring web `moduleStore` + `activeLessonStore` so lesson
/// pages can paint immediately on revisit / in-unit navigation.
abstract final class LessonPageCache {
  static final Map<String, UserModuleItems> _modules = {};
  static final Map<int, LessonPlayback> _lessons = {};
  static final Map<String, Future<UserModuleItems>> _moduleInflight = {};
  static final Map<int, Future<LessonPlayback>> _lessonInflight = {};

  static String moduleKey(int courseId, int moduleId) => '$courseId:$moduleId';

  static UserModuleItems? moduleOf(int courseId, int moduleId) =>
      _modules[moduleKey(courseId, moduleId)];

  static LessonPlayback? lessonOf(int lessonId) => _lessons[lessonId];

  static void putModule(UserModuleItems module) {
    _modules[moduleKey(module.courseId, module.id)] = module;
  }

  static void putLesson(LessonPlayback lesson) {
    _lessons[lesson.id] = lesson;
  }

  static void clear() {
    _modules.clear();
    _lessons.clear();
    _moduleInflight.clear();
    _lessonInflight.clear();
  }

  /// Deduped network fetch; always updates cache.
  static Future<UserModuleItems> loadModule({
    required int courseId,
    required int moduleId,
    required Future<UserModuleItems> Function() fetch,
  }) {
    final key = moduleKey(courseId, moduleId);
    return _moduleInflight.putIfAbsent(key, () async {
      try {
        final fresh = await fetch();
        putModule(fresh);
        return fresh;
      } finally {
        _moduleInflight.remove(key);
      }
    });
  }

  /// Deduped network fetch; always updates cache.
  static Future<LessonPlayback> loadLesson({
    required int lessonId,
    required Future<LessonPlayback> Function() fetch,
  }) {
    return _lessonInflight.putIfAbsent(lessonId, () async {
      try {
        final fresh = await fetch();
        putLesson(fresh);
        return fresh;
      } finally {
        _lessonInflight.remove(lessonId);
      }
    });
  }

  /// Warm neighboring lessons in the background (same unit).
  static void prefetchLessons(
    Iterable<int> lessonIds, {
    required Future<LessonPlayback> Function(int id) fetch,
  }) {
    for (final id in lessonIds) {
      if (id <= 0 || _lessons.containsKey(id) || _lessonInflight.containsKey(id)) {
        continue;
      }
      // Fire and forget — populate cache for instant next navigation.
      loadLesson(lessonId: id, fetch: () => fetch(id));
    }
  }
}
