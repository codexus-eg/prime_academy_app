import '../../core/network/api_client.dart';
import '../upload/upload_api.dart';

abstract final class UsersApi {
  static Future<void> uploadProfileImage(ChatMediaUpload image) async {
    await ApiClient.postVoid('/users/user-image-upload', {
      'image': image.toJson(),
    });
  }
}
