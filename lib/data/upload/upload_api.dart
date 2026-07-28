import '../../core/network/api_client.dart';
import 'upload_mime.dart';
import 'upload_presigned.dart';

class PresignedUpload {
  const PresignedUpload({
    required this.url,
    required this.key,
    this.expireAt,
  });

  final String url;
  final String key;
  final int? expireAt;

  factory PresignedUpload.fromJson(Map<String, dynamic> json) {
    return PresignedUpload(
      url: json['url'] as String? ?? '',
      key: json['key'] as String? ?? '',
      expireAt: json['expireAt'] is int
          ? json['expireAt'] as int
          : json['expiresAt'] is int
              ? json['expiresAt'] as int
              : int.tryParse('${json['expireAt'] ?? json['expiresAt']}'),
    );
  }

  void validate() {
    if (url.trim().isEmpty || key.trim().isEmpty) {
      throw ApiException('تعذّر الحصول على رابط الرفع');
    }
  }
}

class ChatMediaUpload {
  const ChatMediaUpload({
    required this.key,
    required this.name,
    required this.size,
    required this.mimeType,
  });

  final String key;
  final String name;
  final int size;
  final String mimeType;

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'size': size,
        'mime_type': mimeType,
      };
}

abstract final class UploadApi {
  static Future<PresignedUpload> getPresignedUrl(String contentType) async {
    final normalized = UploadMime.mapKnownAliases(
      contentType.split(';').first.trim().toLowerCase(),
    );
    final json = await ApiClient.postJson('/r2/get-presigned-upload-url', {
      'contentType': normalized,
    });
    return PresignedUpload.fromJson(json)..validate();
  }

  static Future<PresignedUpload> getPresignedUrlForProfileImage({
    required String mimeType,
    required String filename,
  }) async {
    final normalized = UploadMime.normalizeProfileImageMime(
      mimeType: mimeType,
      filename: filename,
    );
    if (!UploadMime.isSupportedProfileImageMime(normalized)) {
      throw ApiException('نوع الملف غير مدعوم');
    }
    final json = await ApiClient.postJson('/r2/get-presigned-upload-url', {
      'contentType': normalized,
    });
    return PresignedUpload.fromJson(json)..validate();
  }

  static Future<PresignedUpload> getPresignedUrlForFile({
    required String contentType,
    required String filename,
  }) async {
    final normalized = UploadMime.normalizeChatMime(
      mimeType: contentType,
      filename: filename,
    );
    if (!UploadMime.isSupportedChatMime(normalized)) {
      throw ApiException('نوع الملف غير مدعوم');
    }
    final json = await ApiClient.postJson('/r2/get-presigned-upload-url', {
      'contentType': normalized,
    });
    return PresignedUpload.fromJson(json)..validate();
  }

  static Future<void> uploadBytes({
    required String url,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (url.trim().isEmpty) {
      throw ApiException('تعذّر الحصول على رابط الرفع');
    }

    final normalizedType = contentType.split(';').first.trim().toLowerCase();
    final statusCode = await putPresignedBytes(
      url: url,
      bytes: bytes,
      contentType: normalizedType,
    );
    if (statusCode != null) {
      if (statusCode == -1) {
        throw ApiException(
          'تعذّر رفع الملف. تأكد أن البروكسي يعمل: ./scripts/run_chrome_dev.sh',
        );
      }
      throw ApiException('تعذّر رفع الملف', statusCode: statusCode);
    }
  }

  static Future<void> markUploadCompleted(String key) async {
    await ApiClient.postVoid('/r2/attachment-upload-completed', {
      'key': key,
    });
  }

  static Future<void> registerAttachmentUpload(String key) async {
    await markUploadCompleted(key);
  }
}
