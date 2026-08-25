import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../core/config/api_config.dart';
import '../../core/platform/device_identifier.dart';
import '../auth/auth_session.dart';
import 'sse_event_handlers.dart';
import 'sse_service.dart';

SseService createSseService() => _WebSseService();

class _WebSseService implements SseService {
  web.EventSource? _source;
  Timer? _reconnectTimer;
  var _reconnectDelayMs = 1000;

  @override
  Future<void> connect() async {
    disconnect();

    final user = await AuthSession.load();
    if (user == null || (user.role != 1 && user.role != 2)) return;

    final deviceId = await DeviceIdentifier.get();
    final uri =
        '${ApiConfig.baseUrl}/sse?token=${Uri.encodeComponent(user.token)}&deviceIdentifier=${Uri.encodeComponent(deviceId)}';

    final source = web.EventSource(uri);
    _source = source;

    source.addEventListener(
      'NEW_NOTIFICATION',
      ((web.Event event) {
        final messageEvent = event as web.MessageEvent;
        SseEventHandlers.dispatch(
          'NEW_NOTIFICATION',
          messageEvent.data?.toString() ?? '',
        );
      }).toJS,
    );

    source.addEventListener(
      'MESSAGE_EDITED',
      ((web.Event event) {
        final messageEvent = event as web.MessageEvent;
        SseEventHandlers.dispatch(
          'MESSAGE_EDITED',
          messageEvent.data?.toString() ?? '',
        );
      }).toJS,
    );

    source.addEventListener(
      'MESSAGE_DELETED',
      ((web.Event event) {
        final messageEvent = event as web.MessageEvent;
        SseEventHandlers.dispatch(
          'MESSAGE_DELETED',
          messageEvent.data?.toString() ?? '',
        );
      }).toJS,
    );

    source.addEventListener(
      'INVALID_TOKEN',
      ((web.Event _) {
        SseEventHandlers.dispatch('INVALID_TOKEN', '{}');
      }).toJS,
    );

    source.onerror = ((web.Event _) {
      source.close();
      _source = null;
      _scheduleReconnect();
    }).toJS;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelayMs), () {
      _reconnectDelayMs = (_reconnectDelayMs * 2).clamp(1000, 30000);
      connect();
    });
  }

  @override
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _source?.close();
    _source = null;
    _reconnectDelayMs = 1000;
  }
}
