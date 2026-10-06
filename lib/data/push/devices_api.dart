import '../../core/network/api_client.dart';
import '../../core/platform/device_type.dart';

/// Registers / unregisters the device push identifier with the backend.
abstract final class DevicesApi {
  static Future<void> register({
    required String fid,
    required String platform,
  }) {
    return ApiClient.postVoid('/devices/register', {
      'fid': fid,
      'platform': platform,
    });
  }

  static Future<void> unregister(String fid) {
    return ApiClient.deleteJson('/devices/delete', {'fid': fid});
  }

  static String get nativePlatform {
    final platform = DeviceType.current;
    return platform == 'ios' ? 'ios' : 'android';
  }
}
