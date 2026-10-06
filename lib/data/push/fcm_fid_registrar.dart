import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to native FCM FID registration.
///
/// Legacy [FirebaseMessaging.getToken] only registers the device for token
/// targeting. Admin SDK `FidMulticastMessage` requires the native FID
/// registration path (`FirebaseMessaging.register()` + platform flags).
abstract final class FcmFidRegistrar {
  static const _channel = MethodChannel('prime.academy/fcm_fid');

  /// Registers with FCM via Installation ID and returns the FID, or null.
  static Future<String?> registerAndGetFid() async {
    if (kIsWeb) return null;
    try {
      final fid = await _channel.invokeMethod<String>('registerAndGetFid');
      if (fid == null || fid.isEmpty) {
        debugPrint('[Push] native registerAndGetFid returned empty');
        return null;
      }
      debugPrint('[Push] FCM FID registered for delivery (${fid.length} chars)');
      return fid;
    } on PlatformException catch (error) {
      debugPrint(
        '[Push] native FCM FID register failed: ${error.code} ${error.message}',
      );
      return null;
    } catch (error, stack) {
      debugPrint('[Push] native FCM FID register failed: $error\n$stack');
      return null;
    }
  }
}
