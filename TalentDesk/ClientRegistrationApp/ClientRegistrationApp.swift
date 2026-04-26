import SwiftUI

@main
struct ClientRegistrationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var sessionStore = AppSessionStore()
    @State private var clientStore = ClientStore()
    @State private var settingsStore = AppSettingsStore()
    @State private var pushManager = PushNotificationManager()

    init() {
        // Wire up immediately so the delegate callback never misses
        appDelegate.pushManager = pushManager
    }

    var body: some Scene {
        WindowGroup {
            AppFlowView(sessionStore: sessionStore, clientStore: clientStore)
                .preferredColorScheme(settingsStore.appearance.colorScheme)
                .environment(settingsStore)
                .environment(pushManager)
                .task {
                    pushManager.refreshPermissionStatus()
                    pushManager.registerIfAlreadyAuthorized()
                }
        }
    }
}
