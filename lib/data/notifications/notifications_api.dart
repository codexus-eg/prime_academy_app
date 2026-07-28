import '../../core/network/api_client.dart';
import 'notification_models.dart';

abstract final class NotificationsApi {
  static Future<List<AppNotification>> fetchAll() async {
    final raw = await ApiClient.getJsonList('/notifications');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  static Future<void> markRead(List<int> ids) async {
    if (ids.isEmpty) return;
    await ApiClient.patchJson('/notifications', {'ids': ids});
  }
}
