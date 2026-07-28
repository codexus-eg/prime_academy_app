import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/platform/device_identifier.dart';
import '../auth/auth_session.dart';
import 'sse_event_handlers.dart';
import 'sse_service.dart';

SseService createSseService() => _IoSseService();

class _IoSseService implements SseService {
  http.Client? _client;
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;
  var _reconnectDelayMs = 1000;
  var _cancelled = false;

  @override
  Future<void> connect() async {
    _closeConnection(clearCancelled: false);
    _cancelled = false;

    final user = await AuthSession.load();
    if (user == null || (user.role != 1 && user.role != 2)) return;

    final deviceId = await DeviceIdentifier.get();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/sse?token=${Uri.encodeComponent(user.token)}&deviceIdentifier=${Uri.encodeComponent(deviceId)}',
    );

    final client = http.Client();
    _client = client;

    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);
      if (response.statusCode != 200) {
      client.close();
      _client = null;
      _scheduleReconnect();
      return;
    }

      _reconnectDelayMs = 1000;
      var buffer = '';

      _subscription = response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              buffer += chunk;
              while (buffer.contains('\n\n')) {
                final index = buffer.indexOf('\n\n');
                final rawEvent = buffer.substring(0, index);
                buffer = buffer.substring(index + 2);
                _parseEventBlock(rawEvent);
              }
            },
            onError: (_) => _scheduleReconnect(),
            onDone: () {
              if (!_cancelled) _scheduleReconnect();
            },
          );
    } catch (_) {
      client.close();
      _client = null;
      _scheduleReconnect();
    }
  }

  void _parseEventBlock(String raw) {
    String? eventName;
    final dataLines = <String>[];

    for (final line in raw.split('\n')) {
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    if (eventName == null || dataLines.isEmpty) return;
    SseEventHandlers.dispatch(eventName, dataLines.join('\n'));
  }

  void _scheduleReconnect() {
    if (_cancelled) return;
    _closeConnection(clearCancelled: false);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelayMs), () {
      _reconnectDelayMs = (_reconnectDelayMs * 2).clamp(1000, 30000);
      connect();
    });
  }

  @override
  void disconnect() {
    _closeConnection(clearCancelled: true);
  }

  void _closeConnection({required bool clearCancelled}) {
    if (clearCancelled) _cancelled = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    if (clearCancelled) _reconnectDelayMs = 1000;
  }
}
