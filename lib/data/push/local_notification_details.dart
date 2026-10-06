import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../live_sessions/live_session_alarm.dart';

/// Shared Android/iOS notification presentation for local alarms + tests.
abstract final class LocalNotificationDetailsFactory {
  static const androidIcon = 'ic_notification';

  /// General notifications channel (custom [notification.mp3] sound).
  /// Bumped to `_v2` so Android applies the new sound (channel sound is immutable).
  static const androidChannelId = 'prime_notifications_v2';
  static const androidChannelName = 'إشعارات برايم أكاديمي';

  /// Live session channel — uses [bell_alarm] only. Do not change.
  static const liveChannelId = 'prime_session_live_v2';
  static const liveChannelName = 'حصص مباشرة';

  static const androidGeneralSound = 'notification';
  static const iosGeneralSound = 'notification.mp3';

  static const androidInit = AndroidInitializationSettings(androidIcon);

  /// High-priority session alarm (custom sound when available).
  /// Sound: [bell_alarm] / bell-alarm.mp3 — do not replace.
  static NotificationDetails live({bool withCustomSound = true}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        liveChannelId,
        liveChannelName,
        channelDescription: 'تنبيه عند بدء حصة مباشرة',
        importance: Importance.max,
        priority: Priority.max,
        icon: androidIcon,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(LiveSessionAlarm.vibrationPattern),
        sound: withCustomSound
            ? const RawResourceAndroidNotificationSound('bell_alarm')
            : null,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: withCustomSound ? 'bell-alarm.mp3' : null,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Generic tray notification (regular app notifications).
  /// Sound: [notification.mp3] — separate from live session [bell_alarm].
  static NotificationDetails general() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: 'إشعارات عامة للتطبيق',
        importance: Importance.high,
        priority: Priority.high,
        icon: androidIcon,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(androidGeneralSound),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: iosGeneralSound,
      ),
    );
  }
}
