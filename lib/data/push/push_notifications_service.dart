import 'push_notifications_service_io.dart'
    if (dart.library.js_interop) 'push_notifications_service_web.dart' as impl;

/// Result of an in-app notification delivery probe (no backend required).
class PushDeliveryTestResult {
  const PushDeliveryTestResult({
    required this.immediateOk,
    required this.scheduledOk,
    required this.message,
    this.fid,
  });

  final bool immediateOk;
  final bool scheduledOk;
  final String message;

  /// Firebase Installation ID used as the device identifier (when available).
  final String? fid;

  bool get ok => immediateOk && scheduledOk;
}

/// Identifiers used to verify push registration against the backend DB.
class PushDeviceDebugInfo {
  const PushDeviceDebugInfo({
    this.fid,
    this.error,
  });

  /// Firebase Installation ID (FID) sent as `fid` and stored in
  /// `notification_devices.fid`.
  final String? fid;

  final String? error;
}

/// Firebase Cloud Messaging for Android / iOS. Web uses SSE instead.
///
/// Device identity for the backend uses Firebase Installation ID (FID),
/// not the FCM registration token. FCM remains active for push delivery.
abstract class PushNotificationsService {
  static PushNotificationsService? _instance;

  static PushNotificationsService get instance {
    _instance ??= impl.createPushNotificationsService();
    return _instance!;
  }

  /// Initializes Firebase, local notifications, and tap handlers.
  Future<void> initialize();

  /// Requests permission and upserts the FID for the logged-in student.
  Future<void> registerIfNeeded();

  /// Removes the FID from the backend (must run before session clear).
  Future<void> unregister();

  /// Sends a local test notification now + another in ~15s (no server).
  Future<PushDeliveryTestResult> sendDeliveryTest();

  /// Reads the current Firebase Installation ID for DB comparison.
  Future<PushDeviceDebugInfo> getDeviceDebugInfo();
}
