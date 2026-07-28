import '../../core/network/api_client.dart';
import 'student_awards.dart';
import 'student_incomplete_progress.dart';
import 'student_profile.dart';

abstract final class StudentsApi {
  static Future<StudentProfile> fetchMyProfile() async {
    final json = await ApiClient.getJson('/students/my-profile');
    return StudentProfile.fromJson(json);
  }

  static Future<StudentAwards> fetchStudentAwards(int studentId) async {
    final json = await ApiClient.getJson('/students/awards/$studentId');
    return StudentAwards.fromJson(json);
  }

  static Future<StudentIncompleteProgressReport> fetchIncompleteProgressDetails(
    int courseId,
  ) async {
    final json = await ApiClient.getJson(
      '/students/my-incomplete-progress-details/$courseId',
    );
    return StudentIncompleteProgressReport.fromJson(json);
  }
}
