import 'push_notifications_service.dart';

PushNotificationsService createPushNotificationsService() =>
    _WebPushNotificationsService();

class _WebPushNotificationsService implements PushNotificationsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerIfNeeded() async {}

  @override
  Future<void> unregister() async {}

  @override
  Future<PushDeliveryTestResult> sendDeliveryTest() async {
    return const PushDeliveryTestResult(
      immediateOk: false,
      scheduledOk: false,
      message: 'اختبار الإشعارات متاح على Android / iOS فقط',
    );
  }

  @override
  Future<PushDeviceDebugInfo> getDeviceDebugInfo() async {
    return const PushDeviceDebugInfo(
      error: 'عرض FID متاح على Android / iOS فقط',
    );
  }
}
