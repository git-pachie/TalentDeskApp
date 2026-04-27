import SwiftUI

@main
struct GroceryApp: App {
    @State private var settingsStore = GrocerySettingsStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(settingsStore.appearance.colorScheme)
                .environment(settingsStore)
        }
    }
}
