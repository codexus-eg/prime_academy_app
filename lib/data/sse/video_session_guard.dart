import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../auth/auth_session.dart';
import 'device_id_storage.dart';

class VideoSessionGuard {
  VideoSessionGuard({
    required this.onBlocked,
    required this.onNetworkError,
  });

  static const _heartbeatMs = Duration(seconds: 15);
  static const _base = '/sse/video-page-session';
  static const _maxAcquireFailures = 3;
  static const _maxHeartbeatFailures = 5;

  final VoidCallback onBlocked;
  final VoidCallback onNetworkError;

  Timer? _heartbeatTimer;
  Timer? _retryTimer;
  var _acquired = false;
  var _acquireFailures = 0;
  var _heartbeatFailures = 0;
  var _networkErrorFired = false;
  var _disposed = false;
  String? _deviceId;
  String? _token;

  Future<void> start() async {
    final user = await AuthSession.load();
    if (user == null || user.role != 1) return;

    _token = user.token;
    _deviceId = await DeviceIdStorage.getOrCreate();

    final ok = await _acquire();
    if (_disposed) return;

    if (ok) {
      _startHeartbeat();
    } else if (!_networkErrorFired && _acquireFailures > 0) {
      _retryAcquireLoop();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
    await _release();
  }

  Future<void> _release() async {
    if (!_acquired || _token == null || _deviceId == null) return;
    _acquired = false;
    try {
      await _post('release', {'deviceId': _deviceId!});
    } catch (_) {}
  }

  Future<bool> _acquire() async {
    if (_token == null || _deviceId == null) return false;
    try {
      final res = await _post('acquire', {'deviceId': _deviceId!});
      if (res.statusCode == 409) {
        _acquireFailures = 0;
        onBlocked();
        return false;
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _acquireFailures = 0;
        _acquired = true;
        return true;
      }
      throw Exception('Status ${res.statusCode}');
    } catch (_) {
      if (_disposed) return false;
      _acquireFailures += 1;
      if (_acquireFailures >= _maxAcquireFailures) {
        _handleNetworkError();
      }
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatFailures = 0;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatMs, (_) => _heartbeat());
  }

  Future<void> _heartbeat() async {
    if (!_acquired || _token == null || _deviceId == null) return;
    try {
      final res = await _post('heartbeat', {'deviceId': _deviceId!});
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _heartbeatFailures = 0;
        _acquired = true;
        return;
      }
      if (res.statusCode == 409) {
        _heartbeatFailures = 0;
        _acquired = false;
        _heartbeatTimer?.cancel();
        onBlocked();
        return;
      }
      throw Exception('Status ${res.statusCode}');
    } catch (_) {
      if (_disposed) return;
      _acquired = false;
      _heartbeatTimer?.cancel();
      _heartbeatFailures += 1;
      if (_heartbeatFailures >= _maxHeartbeatFailures) {
        _handleNetworkError();
        return;
      }
      _acquireFailures = 0;
      _retryAcquireLoop();
    }
  }

  Future<void> _retryAcquireLoop() async {
    while (!_disposed && !_networkErrorFired) {
      await Future<void>.delayed(const Duration(seconds: 5));
      if (_disposed || _networkErrorFired) return;
      final ok = await _acquire();
      if (ok) {
        _startHeartbeat();
        return;
      }
      if (_acquireFailures == 0) return;
      if (_networkErrorFired) return;
    }
  }

  void _handleNetworkError() {
    if (_networkErrorFired) return;
    _networkErrorFired = true;
    _acquired = false;
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
    onNetworkError();
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_base/$endpoint');
    return http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
  }
}
