import '../../core/network/api_client.dart';
import 'course_rank.dart';
import 'module_material.dart';
import 'user_course.dart';

abstract final class CoursesApi {

  static Future<List<CourseRankEntry>> fetchRanksByCourse(int courseId) async {
    final list = await ApiClient.getJsonList('/courses/ranks/$courseId');
    return list
        .whereType<Map<String, dynamic>>()
        .map(CourseRankEntry.fromJson)
        .toList();
  }

  static Future<UserCourse> fetchCourseForUser(int courseId) async {
    final json = await ApiClient.getJson('/courses/$courseId/user');
    return UserCourse.fromJson(json);
  }

  static Future<UserModuleItems> fetchModuleItems({
    required int courseId,
    required int moduleId,
  }) async {
    final json =
        await ApiClient.getJson('/module-items/$courseId/$moduleId/user');
    return UserModuleItems.fromJson(json);
  }

  static Future<LessonPlayback> fetchLesson(int lessonId) async {
    final json = await ApiClient.getJson('/module-items/lesson/$lessonId/user');
    return LessonPlayback.fromJson(json);
  }

  static Future<List<ModuleMaterial>> fetchModuleMaterials(int moduleId) async {
    final list = await ApiClient.getJsonList('/course-modules/$moduleId/materials');
    return list
        .whereType<Map<String, dynamic>>()
        .map(ModuleMaterial.fromJson)
        .toList();
  }

  static Future<bool> saveVideoProgress({
    required int lessonId,
    required int progressSeconds,
  }) async {
    final json = await ApiClient.postJson(
      '/module-items/lesson/progress/$lessonId',
      {'progress': progressSeconds},
    );
    return json['watched'] == true;
  }

  static Future<void> giveTrophy(int lessonId) async {
    await ApiClient.postJson('/module-items/lesson/give-trophy/$lessonId');
  }

  static Future<void> markLessonCardViewed({
    required int lessonId,
    required int cardId,
  }) async {
    await ApiClient.postVoid(
      '/module-items/$lessonId/lesson_cards/view/$cardId',
    );
  }
}
