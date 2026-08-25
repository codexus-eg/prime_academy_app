import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../auth/auth_session.dart';
import '../chat/chat_models.dart';
import '../notifications/notification_models.dart';
import '../notifications/notification_store.dart';
import '../notifications/notifications_api.dart';
import 'sse_service.dart';

abstract final class SseEventHandlers {
  static Uri? Function()? currentUri;
  static VoidCallback? onInvalidToken;

  static void dispatch(String eventName, String data) {
    switch (eventName) {
      case 'NEW_NOTIFICATION':
        handleNewNotification(data);
      case 'MESSAGE_EDITED':
        handleChatMutation(data, edited: true);
      case 'MESSAGE_DELETED':
        handleChatMutation(data, deleted: true);
      case 'INVALID_TOKEN':
        unawaited(_handleInvalidToken());
    }
  }

  static Future<void> _handleInvalidToken() async {
    await AuthSession.clear();
    onInvalidToken?.call();
  }

  static void handleNewNotification(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final root = Map<String, dynamic>.from(decoded);
      final inner = root['payload'] is Map
          ? Map<String, dynamic>.from(root['payload'] as Map)
          : root;

      final type = (inner['type'] as String?) ?? (root['type'] as String?);
      final dataRaw = inner['data'] ?? root['data'];
      if (type == null || dataRaw is! Map) return;
      final data = Map<String, dynamic>.from(dataRaw);

      final notification = AppNotification(
        id: _asInt(inner['id'] ?? root['id']),
        type: NotificationType.fromApi(type),
        data: NotificationData.fromJson(data),
        isRead: inner['is_read'] == true || root['is_read'] == true,
        createdAt: DateTime.tryParse(
              '${inner['created_at'] ?? root['created_at'] ?? ''}',
            ) ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(
              '${inner['updated_at'] ?? root['updated_at'] ?? ''}',
            ) ??
            DateTime.now(),
      );

      if (notification.type == NotificationType.chat) {
        _handleIncomingChat(notification, data);
        return;
      }

      NotificationStore.instance.addIncoming(notification);
    } catch (_) {}
  }

  static void _handleIncomingChat(
    AppNotification notification,
    Map<String, dynamic> data,
  ) {
    final messageJson = data['message'];
    if (messageJson is Map<String, dynamic>) {
      try {
        ChatLiveHub.instance.pushMessage(ChatMessage.fromJson(messageJson));
      } catch (_) {}
    }

    final viewing = _isViewingChat(
      itemId: notification.data.itemId,
      chatId: notification.data.chatId,
    );

    final stored = viewing
        ? notification.copyWith(isRead: true)
        : notification;
    NotificationStore.instance.addIncoming(stored);

    if (viewing && !notification.isRead) {
      unawaited(NotificationsApi.markRead([notification.id]));
    }
  }

  static bool _isViewingChat({int? itemId, int? chatId}) {
    final uri = currentUri?.call();
    if (uri == null || itemId == null) return false;
    final lessonMatch = RegExp(r'/lessons/(\d+)').firstMatch(uri.path);
    if (lessonMatch == null) return false;
    if (lessonMatch.group(1) != '$itemId') return false;
    if (uri.queryParameters['active_tab'] != 'chat') return false;
    if (chatId == null) return true;
    final queryChat = uri.queryParameters['chat_id'];
    return queryChat == null || queryChat == '$chatId';
  }

  static void handleChatMutation(
    String raw, {
    bool edited = false,
    bool deleted = false,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final payload = decoded['payload'] is Map<String, dynamic>
          ? decoded['payload'] as Map<String, dynamic>
          : decoded;

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
    } catch (_) {}
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

