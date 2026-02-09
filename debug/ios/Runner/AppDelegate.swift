import Flutter
import UIKit
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        ATTrackingManager.requestTrackingAuthorization { status in
        }
    }

    @objc func didBecomeActiveNotification() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .denied:
                    print("AuthorizationStatus is denied")
                case .notDetermined:
                    print("AuthorizationStatus is notDetermined")
                case .restricted:
                    print("AuthorizationStatus is restricted")
                case .authorized:
                    print("AuthorizationStatus is authorized")
                @unknown default:
                    print("Invalid authorization status")
                }
            }
        }
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[PUSH] didFailToRegisterForRemoteNotificationsWithError: \(error.localizedDescription)")
    }

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[PUSH] didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
        //        Store.profileAPI.pushUserToken(deviceToken)
    }

    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("[PUSH] didReceiveRemoteNotification: \(userInfo)")

        completionHandler(UIBackgroundFetchResult.newData) // 加上这个，在app也会显示通知
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        resetBadgeNumber()
        completionHandler([.sound, .badge, .alert]) // 加上这个，在app也会显示通知
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        resetBadgeNumber()
        // 这里处理点击通知进来
    }

    private func resetBadgeNumber() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    override func application(
        _ app: UIApplication,
        open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return false
    }
}
