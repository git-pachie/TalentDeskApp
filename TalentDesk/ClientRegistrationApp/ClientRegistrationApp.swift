import SwiftUI

@main
struct ClientRegistrationApp: App {
    @State private var sessionStore = AppSessionStore()
    @State private var clientStore = ClientStore()
    @State private var settingsStore = AppSettingsStore()

    var body: some Scene {
        WindowGroup {
            AppFlowView(sessionStore: sessionStore, clientStore: clientStore)
                .preferredColorScheme(settingsStore.appearance.colorScheme)
                .environment(settingsStore)
        }
    }
}
