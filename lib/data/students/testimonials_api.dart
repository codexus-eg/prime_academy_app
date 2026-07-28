import '../../core/network/api_client.dart';

abstract final class TestimonialsApi {

  static Future<void> submit({
    required int courseId,
    required String content,
  }) async {
    await ApiClient.postVoid('/students/testimonials', {
      'content': content,
      'courseId': courseId,
    });
  }

  static Future<void> ignore({required int courseId}) async {
    await ApiClient.postVoid('/students/testimonials/ignore', {
      'courseId': courseId,
    });
  }
}
