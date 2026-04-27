import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var pushManager: PushNotificationManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🚀 AppDelegate didFinishLaunching")

        // MARK: - Global appearance
        configureGlobalAppearance()

        // Set self as notification delegate so we can show alerts in foreground
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Current push permission: \(settings.authorizationStatus.rawValue)")

            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    print("🔔 Calling registerForRemoteNotifications()...")
                    application.registerForRemoteNotifications()
                }
            } else if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    print("🔔 Permission result: granted=\(granted), error=\(error?.localizedDescription ?? "none")")
                    if granted {
                        DispatchQueue.main.async {
                            print("🔔 Calling registerForRemoteNotifications()...")
                            application.registerForRemoteNotifications()
                        }
                    }
                }
            } else {
                print("🔔 Push notifications denied by user")
            }
        }

        return true
    }

    // MARK: - APNs Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("========================================")
        print("📱 APNs Device Token: \(token)")
        print("========================================")
        pushManager?.didRegister(tokenData: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("========================================")
        print("❌ APNs registration FAILED: \(error.localizedDescription)")
        print("========================================")
        pushManager?.didFailToRegister(error: error)
    }

    // MARK: - Show notifications even when app is in foreground

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Received notification in foreground: \(notification.request.content.title)")
        completionHandler([.banner, .badge, .sound])
    }

    // MARK: - Handle notification tap

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 User tapped notification: \(response.notification.request.content.title)")
        completionHandler()
    }

    // MARK: - Global UI Appearance

    private func configureGlobalAppearance() {
        let accentColor = UIColor(AppTheme.accent)
        UINavigationBar.appearance().tintColor = accentColor
        UITabBar.appearance().tintColor = accentColor
    }
}
