import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../upload/upload_api.dart';

class ChatMedia {
  const ChatMedia({
    required this.id,
    required this.url,
    required this.mimeType,
    this.filename,
  });

  final int id;
  final String url;
  final String mimeType;
  final String? filename;

  String get resolvedUrl => ApiConfig.mediaUrl(url);

  factory ChatMedia.fromJson(Map<String, dynamic> json) {
    return ChatMedia(
      id: _parseInt(json['id']) ?? 0,
      url: (json['url'] as String? ?? json['key'] as String? ?? ''),
      mimeType: (json['mime_type'] as String? ?? json['mimeType'] as String? ?? ''),
      filename: json['filename'] as String? ?? json['name'] as String?,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.senderRole,
    this.media,
    this.isPending = false,
  });

  final int id;
  final int chatId;
  final int senderId;
  final String message;
  final String createdAt;
  final int? senderRole;
  final ChatMedia? media;
  final bool isPending;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'];
    ChatMedia? media;
    if (mediaJson is Map<String, dynamic>) {
      media = ChatMedia.fromJson(mediaJson);
      if (media.url.isEmpty && media.mimeType.isEmpty) {
        media = null;
      }
    }
    return ChatMessage(
      id: _parseInt(json['id']) ?? 0,
      chatId: _parseInt(json['chat_id']) ?? 0,
      senderId: _parseInt(json['sender_id']) ?? 0,
      message: (json['message'] as String? ?? ''),
      createdAt: _parseTimestamp(json['created_at']),
      senderRole: _optionalInt(json['sender_role']),
      media: media,
    );
  }

  ChatMessage copyWith({
    String? message,
    ChatMedia? media,
    bool? isPending,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      message: message ?? this.message,
      createdAt: createdAt,
      senderRole: senderRole,
      media: media ?? this.media,
      isPending: isPending ?? this.isPending,
    );
  }

  bool get isAudioMessage =>
      media != null && media!.mimeType.startsWith('audio/');

  ChatMessage pendingCopy() => copyWith(isPending: true);
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

String _parseTimestamp(Object? value) {
  if (value == null) return DateTime.now().toUtc().toIso8601String();
  if (value is String && value.isNotEmpty) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value).toUtc().toIso8601String();
  }
  return value.toString();
}

abstract final class ChatApi {

  static Future<List<ChatMessage>> fetchMessages({
    required int chatId,
    int page = 1,
  }) async {
    final list =
        await ApiClient.getJsonList('/chats/$chatId?page=$page');
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  static Future<ChatMessage> sendMessage({
    required int chatId,
    required String message,
    required int courseId,
    ChatMediaUpload? media,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'courseId': courseId,
      if (media != null) 'media': media.toJson(),
    };
    final json = await ApiClient.postJson('/chats/$chatId', body);
    return ChatMessage.fromJson(json);
  }

  static Future<ChatMessage> editMessage({
    required int chatId,
    required int messageId,
    required String message,
  }) async {
    final json = await ApiClient.patchJsonMap(
      '/chats/$chatId/$messageId',
      {'message': message},
    );
    return ChatMessage.fromJson(json);
  }

  static Future<void> deleteMessage({
    required int chatId,
    required int messageId,
  }) async {
    await ApiClient.deleteVoid('/chats/$chatId/$messageId');
  }
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
