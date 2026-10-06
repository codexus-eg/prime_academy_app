import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../presentation/home/widgets/notification_link.dart';
import '../../presentation/home/widgets/notification_navigator.dart';
import '../../presentation/home/widgets/notification_pending.dart';
import '../../router/app_router.dart';
import '../../firebase_options.dart';
import '../auth/auth_session.dart';
import '../live_sessions/live_sessions_watcher.dart';
import '../meeting_schedules/meeting_sessions_local_scheduler.dart';
import '../meeting_schedules/meeting_sessions_sync.dart';
import 'devices_api.dart';
import 'fcm_fid_registrar.dart';
import 'local_notification_details.dart';
import 'local_notifications_hub.dart';
import 'push_notifications_service.dart';

const _fidPrefsKey = 'notification_device_fid';
const _legacyTokenPrefsKey = 'fcm_device_token';
const _testImmediateId = 910001;
const _testScheduledId = 910002;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS already displays the tray notification when the payload includes
  // a `notification` block. Keep this handler light.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

PushNotificationsService createPushNotificationsService() =>
    _IoPushNotificationsService();

class _IoPushNotificationsService implements PushNotificationsService {
  final _localNotifications = LocalNotificationsHub.plugin;
  var _initialized = false;
  var _registering = false;
  var _firebaseReady = false;
  var _localReady = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    LocalNotificationsHub.ensureTimeZones();
    MeetingSessionsLocalScheduler.bind(_localNotifications);

    // Local notifications must work even when Firebase init fails.
    try {
      await _initializeLocalNotifications();
      _localReady = true;
    } catch (error, stack) {
      debugPrint('[Push] local notifications init failed: $error\n$stack');
      _localReady = false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseReady = true;
    } catch (error, stack) {
      debugPrint('[Push] Firebase init failed: $error\n$stack');
      _firebaseReady = false;
      _initialized = true;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromRemoteMessage);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _storePendingFromRemoteMessage(initial);
    }

    // FID-based FCM registration is handled natively (see FcmFidRegistrar).
    // Do not use getToken / onTokenRefresh — those are legacy token targeting
    // and can leave FIDs unregistered for Admin SDK FidMulticastMessage.

    _initialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final ok = await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: LocalNotificationDetailsFactory.androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    debugPrint('[Push] local notifications initialize => $ok');

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        LocalNotificationDetailsFactory.androidChannelId,
        LocalNotificationDetailsFactory.androidChannelName,
        description: 'إشعارات عامة للتطبيق',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          LocalNotificationDetailsFactory.androidGeneralSound,
        ),
      ),
    );
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        LocalNotificationDetailsFactory.liveChannelId,
        LocalNotificationDetailsFactory.liveChannelName,
        description: 'تنبيه عند بدء حصة مباشرة',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('bell_alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
          const [0, 400, 120, 400, 120, 450, 100, 500],
        ),
      ),
    );

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse?.payload != null &&
        launchResponse!.payload!.isNotEmpty) {
      try {
        final decoded = jsonDecode(launchResponse.payload!);
        if (decoded is Map) {
          final data =
              decoded.map((key, value) => MapEntry('$key', '$value'));
          _storePending(NotificationLink.fromPayload(data));
          if (data['type'] == 'SESSION_LIVE') {
            LiveSessionsWatcher.surfaceFromPayload(data, playAlarm: false);
          }
        }
      } catch (error) {
        debugPrint('[Push] launch payload parse failed: $error');
      }
    }
  }

  Future<void> _ensureLocalReady() async {
    if (_localReady) return;
    LocalNotificationsHub.ensureTimeZones();
    MeetingSessionsLocalScheduler.bind(_localNotifications);
    await _initializeLocalNotifications();
    _localReady = true;
  }

  @override
  Future<void> registerIfNeeded() async {
    if (kIsWeb || !_initialized || _registering) return;
    _registering = true;
    try {
      final user = await AuthSession.load();
      if (user == null || user.id <= 0) return;

      try {
        await _ensureLocalReady();
      } catch (error) {
        debugPrint('[Push] ensure local ready failed: $error');
      }

      await _requestNotificationPermissions();

      if (_firebaseReady) {
        await _registerDeviceFid();
      } else {
        debugPrint('[Push] skip device FID register — Firebase not ready');
      }

      MeetingSessionsSync.instance.attach();
      await MeetingSessionsSync.instance.sync();
    } catch (error, stack) {
      debugPrint('[Push] register failed: $error\n$stack');
      try {
        MeetingSessionsSync.instance.attach();
        await MeetingSessionsSync.instance.sync();
      } catch (syncError) {
        debugPrint('[Push] local sync recovery failed: $syncError');
      }
    } finally {
      _registering = false;
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      try {
        final enabled = await android?.areNotificationsEnabled();
        debugPrint('[Push] Android notifications enabled=$enabled');
        if (enabled != true) {
          final granted = await android?.requestNotificationsPermission();
          debugPrint('[Push] Android POST_NOTIFICATIONS granted=$granted');
        }
      } catch (error) {
        debugPrint('[Push] Android notification permission failed: $error');
      }
      await MeetingSessionsLocalScheduler.requestExactAlarmPermissionIfNeeded();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      try {
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('[Push] iOS local notification permission granted=$granted');
      } catch (error) {
        debugPrint('[Push] iOS local permission failed: $error');
      }
    }
  }

  Future<void> _registerDeviceFid() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[Push] FCM authorizationStatus=${settings.authorizationStatus}',
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: true,
        );
      }

      // Native FCM FID registration (not legacy getToken). Required for
      // Admin SDK delivery via FidMulticastMessage / fids.
      final fid = await FcmFidRegistrar.registerAndGetFid();
      if (fid == null || fid.isEmpty) {
        debugPrint('[Push] skip backend register — FCM FID not ready');
        return;
      }

      await _migrateLegacyDeviceIdIfNeeded(fid);

      await DevicesApi.register(
        fid: fid,
        platform: DevicesApi.nativePlatform,
      );
      await _persistFid(fid);
      debugPrint('[Push] device FID registered with backend (${fid.length} chars)');
    } catch (error, stack) {
      debugPrint('[Push] device FID register failed: $error\n$stack');
    }
  }

  /// Best-effort: drop a previously stored FCM token (or stale FID) from the
  /// backend so only the current Installation ID remains linked to the user.
  Future<void> _migrateLegacyDeviceIdIfNeeded(String currentFid) async {
    final previous = await _readPersistedFid();
    if (previous == null || previous.isEmpty || previous == currentFid) {
      return;
    }
    try {
      await DevicesApi.unregister(previous);
      debugPrint('[Push] legacy device id unregistered from backend');
    } catch (error) {
      debugPrint('[Push] legacy device id unregister failed: $error');
    }
  }

  @override
  Future<void> unregister() async {
    if (kIsWeb) return;
    try {
      MeetingSessionsSync.instance.detach();
      await MeetingSessionsSync.instance.clear();

      // Prefer persisted id (covers legacy FCM-token migrations); fall back to live FID.
      var fid = await _readPersistedFid();
      if ((fid == null || fid.isEmpty) && _firebaseReady) {
        try {
          final live = await FirebaseInstallations.instance.getId();
          if (live.isNotEmpty) fid = live;
        } catch (_) {}
      }
      if (fid == null || fid.isEmpty) return;
      await DevicesApi.unregister(fid);
    } catch (error) {
      debugPrint('[Push] unregister failed: $error');
    } finally {
      await _persistFid(null);
    }
  }

  @override
  Future<PushDeliveryTestResult> sendDeliveryTest() async {
    if (kIsWeb) {
      return const PushDeliveryTestResult(
        immediateOk: false,
        scheduledOk: false,
        message: 'اختبار الإشعارات متاح على Android / iOS فقط',
      );
    }

    if (!_initialized) {
      await initialize();
    }

    Object? immediateError;
    Object? scheduledError;
    var immediateOk = false;
    var scheduledOk = false;

    try {
      await _ensureLocalReady();
      await _requestNotificationPermissions();
    } catch (error) {
      return PushDeliveryTestResult(
        immediateOk: false,
        scheduledOk: false,
        message: 'تهيئة الإشعارات فشلت: $error',
      );
    }

    try {
      await _localNotifications.cancel(id: _testImmediateId);
      await _localNotifications.cancel(id: _testScheduledId);
    } catch (_) {}

    final payloadImmediate = jsonEncode({
      'type': 'SESSION_LIVE',
      'title': 'اختبار إشعار فوري',
      'source': 'delivery_test_immediate',
    });
    final payloadScheduled = jsonEncode({
      'type': 'SESSION_LIVE',
      'title': 'اختبار إشعار مجدول',
      'source': 'delivery_test_scheduled',
    });

    try {
      await _showWithFallback(
        id: _testImmediateId,
        title: 'اختبار إشعار فوري',
        body: 'إذا ظهر هذا التنبيه فالقناة المحلية تعمل الآن',
        payload: payloadImmediate,
      );
      immediateOk = true;
      debugPrint('[Push] delivery test: immediate notification shown');
    } catch (error, stack) {
      immediateError = error;
      debugPrint('[Push] delivery test immediate failed: $error\n$stack');
    }

    final when = LocalNotificationsHub.tzNowPlus(const Duration(seconds: 15));
    try {
      await _scheduleWithFallback(
        id: _testScheduledId,
        title: 'اختبار إشعار مجدول',
        body: 'وصل بعد 15 ثانية — الجدولة المحلية تعمل',
        when: when,
        payload: payloadScheduled,
      );
      scheduledOk = true;
      debugPrint(
        '[Push] delivery test: scheduled for ${when.toIso8601String()}',
      );
    } catch (error, stack) {
      scheduledError = error;
      debugPrint('[Push] delivery test schedule failed: $error\n$stack');
    }

    String? fid;
    if (_firebaseReady) {
      fid = await FcmFidRegistrar.registerAndGetFid();
      if (fid != null) {
        debugPrint('[Push] delivery test FID:\n$fid');
      }
    }

    final parts = <String>[
      if (immediateOk)
        'ظهر إشعار فوري'
      else
        'فشل الإشعار الفوري${immediateError == null ? '' : ': $immediateError'}',
      if (scheduledOk)
        'سيصل إشعار ثانٍ خلال ~15 ثانية'
      else
        'فشل جدولة الإشعار الثاني${scheduledError == null ? '' : ': $scheduledError'}',
    ];

    return PushDeliveryTestResult(
      immediateOk: immediateOk,
      scheduledOk: scheduledOk,
      message: parts.join('\n'),
      fid: fid,
    );
  }

  @override
  Future<PushDeviceDebugInfo> getDeviceDebugInfo() async {
    if (kIsWeb) {
      return const PushDeviceDebugInfo(
        error: 'عرض معرّف الجهاز متاح على Android / iOS فقط',
      );
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_firebaseReady) {
      return const PushDeviceDebugInfo(error: 'Firebase غير جاهز');
    }
    try {
      final fid = await FcmFidRegistrar.registerAndGetFid();
      return PushDeviceDebugInfo(fid: fid);
    } catch (error) {
      return PushDeviceDebugInfo(error: '$error');
    }
  }

  Future<void> _showWithFallback({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: LocalNotificationDetailsFactory.live(),
        payload: payload,
      );
      return;
    } catch (error) {
      debugPrint('[Push] show with custom sound failed: $error');
    }

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: LocalNotificationDetailsFactory.general(),
      payload: payload,
    );
  }

  Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
  }) async {
    Future<void> attempt(
      NotificationDetails details,
      AndroidScheduleMode mode,
    ) {
      return _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    try {
      await attempt(
        LocalNotificationDetailsFactory.live(),
        AndroidScheduleMode.alarmClock,
      );
      return;
    } catch (error) {
      debugPrint('[Push] alarmClock+sound schedule failed: $error');
    }

    try {
      await attempt(
        LocalNotificationDetailsFactory.general(),
        AndroidScheduleMode.alarmClock,
      );
      return;
    } catch (error) {
      debugPrint('[Push] alarmClock+general schedule failed: $error');
    }

    try {
      await attempt(
        LocalNotificationDetailsFactory.live(),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
      return;
    } catch (error) {
      debugPrint('[Push] exact+sound schedule failed: $error');
    }

    try {
      await attempt(
        LocalNotificationDetailsFactory.general(),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
      return;
    } catch (error) {
      debugPrint('[Push] exact+general schedule failed: $error');
    }

    await attempt(
      LocalNotificationDetailsFactory.general(),
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = _stringData(message.data);
    if (data['type'] == 'SESSION_LIVE') {
      final enriched = Map<String, String>.from(data);
      final body = message.notification?.body?.trim();
      if ((enriched['title'] ?? '').isEmpty && body != null && body.isNotEmpty) {
        enriched['title'] = body;
      }
      LiveSessionsWatcher.surfaceFromPayload(enriched);
      return;
    }

    final notification = message.notification;
    final title = notification?.title ?? '';
    final body = notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    try {
      await _ensureLocalReady();
      await _localNotifications.show(
        id: message.hashCode & 0x7FFFFFFF,
        title: title.isEmpty ? 'Prime Academy' : title,
        body: body,
        notificationDetails: LocalNotificationDetailsFactory.general(),
        payload: jsonEncode(message.data),
      );
    } catch (error) {
      debugPrint('[Push] foreground local show failed: $error');
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final data = decoded.map((key, value) => MapEntry('$key', '$value'));
      if (data['type'] == 'SESSION_LIVE') {
        LiveSessionsWatcher.surfaceFromPayload(data, playAlarm: false);
      }
      _openFromData(data);
    } catch (error) {
      debugPrint('[Push] local tap parse failed: $error');
    }
  }

  void _openFromRemoteMessage(RemoteMessage message) {
    final data = _stringData(message.data);
    if (data['type'] == 'SESSION_LIVE') {
      LiveSessionsWatcher.surfaceFromPayload(data, playAlarm: false);
    }
    _openFromData(data);
  }

  void _storePendingFromRemoteMessage(RemoteMessage message) {
    _storePending(NotificationLink.fromPayload(_stringData(message.data)));
  }

  void _openFromData(Map<String, String> data) {
    final target = NotificationLink.fromPayload(data);
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _storePending(target);
      return;
    }
    unawaited(NotificationNavigator.open(context, target));
  }

  void _storePending(NotificationNavigationTarget target) {
    NotificationPending.storeTarget(target);
  }

  Map<String, String> _stringData(Map<Object?, Object?> data) {
    return {
      for (final entry in data.entries) '${entry.key}': '${entry.value}',
    };
  }

  Future<void> _persistFid(String? fid) async {
    final prefs = await SharedPreferences.getInstance();
    // Drop legacy FCM-token-as-device-id key if present.
    await prefs.remove(_legacyTokenPrefsKey);
    if (fid == null || fid.isEmpty) {
      await prefs.remove(_fidPrefsKey);
      return;
    }
    await prefs.setString(_fidPrefsKey, fid);
  }

  Future<String?> _readPersistedFid() async {
    final prefs = await SharedPreferences.getInstance();
    final fid = prefs.getString(_fidPrefsKey);
    if (fid != null && fid.isNotEmpty) return fid;
    // One-time migration: older builds stored the FCM registration token here.
    final legacy = prefs.getString(_legacyTokenPrefsKey);
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return null;
  }
}
