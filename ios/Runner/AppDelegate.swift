import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseInstallations
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let fcmFidChannelName = "prime.academy/fcm_fid"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupFcmFidChannel()
    return ok
  }

  private func setupFcmFidChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      DispatchQueue.main.async { [weak self] in
        self?.setupFcmFidChannel()
      }
      return
    }

    let channel = FlutterMethodChannel(
      name: fcmFidChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "registerAndGetFid" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.registerAndGetFid(result: result)
    }
  }

  /// Registers with FCM via FID (requires FirebaseMessagingInstallationIdEnabled=YES),
  /// then returns the Installation ID for Admin SDK FidMulticastMessage targeting.
  private func registerAndGetFid(result: @escaping FlutterResult) {
    guard FirebaseApp.app() != nil else {
      result(
        FlutterError(
          code: "FIREBASE_NOT_READY",
          message: "FirebaseApp is not configured yet",
          details: nil
        )
      )
      return
    }

    Messaging.messaging().register { error in
      if let error = error {
        result(
          FlutterError(
            code: "FCM_REGISTER_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }

      Installations.installations().installationID { fid, installError in
        if let fid = fid, !fid.isEmpty {
          result(fid)
          return
        }
        result(
          FlutterError(
            code: "FID_UNAVAILABLE",
            message: installError?.localizedDescription ?? "Installations.getID failed",
            details: nil
          )
        )
      }
    }
  }
}
