import Foundation
import Observation
import UserNotifications
import UIKit

@Observable
final class PushNotificationManager {
    var deviceToken: String?
    var permissionStatus: UNAuthorizationStatus = .notDetermined
    var registrationError: String?

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    self.registrationError = error.localizedDescription
                    NSLog("Push permission error: \(error.localizedDescription)")
                    return
                }
                self.refreshPermissionStatus()
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func refreshPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
            }
        }
    }

    /// Re-registers for remote notifications if the user already granted permission.
    /// Call this on every app launch so the delegate always receives the token.
    func registerIfAlreadyAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func didRegister(tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        registrationError = nil
        print("========================================")
        print("📱 APNs Device Token: \(token)")
        print("========================================")
        NSLog("📱 APNs device token: \(token)")
    }

    func didFailToRegister(error: Error) {
        deviceToken = nil
        registrationError = error.localizedDescription
        NSLog("❌ APNs registration failed: \(error.localizedDescription)")
    }
}
