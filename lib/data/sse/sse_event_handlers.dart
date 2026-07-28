import 'dart:convert';

import '../auth/auth_session.dart';
import '../chat/chat_models.dart';
import 'sse_service.dart';

abstract final class SseEventHandlers {
  static void dispatch(String eventName, String data) {
    switch (eventName) {
      case 'NEW_NOTIFICATION':
        handleNewNotification(data);
      case 'MESSAGE_EDITED':
        handleChatMutation(data, edited: true);
      case 'MESSAGE_DELETED':
        handleChatMutation(data, deleted: true);
      case 'INVALID_TOKEN':
        AuthSession.clear();
    }
  }

  static void handleNewNotification(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final payload = decoded['payload'];
      if (payload is! Map<String, dynamic>) return;

      final type = payload['type'] as String?;
      final data = payload['data'];
      if (type != 'CHAT' || data is! Map<String, dynamic>) return;

      final messageJson = data['message'];
      if (messageJson is! Map<String, dynamic>) return;

      ChatLiveHub.instance.pushMessage(ChatMessage.fromJson(messageJson));
    } catch (_) {

    }
  }

  static void handleChatMutation(
    String raw, {
    bool edited = false,
    bool deleted = false,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final payload = decoded['payload'];
      if (payload is! Map<String, dynamic>) return;

      final chatId = payload['chat_id'];
      if (edited) {
        final message = payload['message'];
        if (message is Map<String, dynamic>) {
          ChatLiveHub.instance.pushEdited(ChatMessage.fromJson(message));
        }
      } else if (deleted) {
        final messageId = payload['message_id'];
        if (chatId != null && messageId != null) {
          ChatLiveHub.instance.pushDeleted(
            chatId: chatId is int ? chatId : int.parse('$chatId'),
            messageId: messageId is int ? messageId : int.parse('$messageId'),
          );
        }
      }
    } catch (_) {

    }
  }
}
