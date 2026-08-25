import 'dart:async';

import 'package:flutter/foundation.dart';

import '../chat/chat_models.dart';
import 'sse_service_io.dart'
    if (dart.library.js_interop) 'sse_service_web.dart' as impl;

class ChatLiveHub extends ChangeNotifier {
  ChatLiveHub._();
  static final ChatLiveHub instance = ChatLiveHub._();

  final _messageListeners = <int, void Function(ChatMessage message)>{};
  final _editListeners = <int, void Function(ChatMessage message)>{};
  final _deleteListeners = <int, void Function(int messageId)>{};

  void subscribe({
    required int chatId,
    void Function(ChatMessage message)? onMessage,
    void Function(ChatMessage message)? onEdited,
    void Function(int messageId)? onDeleted,
  }) {
    if (onMessage != null) _messageListeners[chatId] = onMessage;
    if (onEdited != null) _editListeners[chatId] = onEdited;
    if (onDeleted != null) _deleteListeners[chatId] = onDeleted;
  }

  void unsubscribe(int chatId) {
    _messageListeners.remove(chatId);
    _editListeners.remove(chatId);
    _deleteListeners.remove(chatId);
  }

  void pushMessage(ChatMessage message) {
    _messageListeners[message.chatId]?.call(message);
    notifyListeners();
  }

  void pushEdited(ChatMessage message) {
    _editListeners[message.chatId]?.call(message);
    notifyListeners();
  }

  void pushDeleted({required int chatId, required int messageId}) {
    _deleteListeners[chatId]?.call(messageId);
    notifyListeners();
  }
}

abstract class SseService {
  static SseService? _instance;

  static SseService get instance {
    _instance ??= impl.createSseService();
    return _instance!;
  }

  Future<void> connect();
  void disconnect();
}
