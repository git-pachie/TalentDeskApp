import SwiftUI

@main
struct GroceryApp: App {
    @State private var settingsStore = GrocerySettingsStore()

    var body: some Scene {
        WindowGroup {
            ThemeRoot(settingsStore: settingsStore)
        }
    }
}

struct ThemeRoot: View {
    let settingsStore: GrocerySettingsStore

    var body: some View {
        RootTabView()
            .environment(settingsStore)
            .task(id: settingsStore.appearance) {
                setWindowStyle(settingsStore.appearance.uiStyle)
            }
    }

    private func setWindowStyle(_ style: UIUserInterfaceStyle) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        UIView.animate(withDuration: 0.3) {
            window.overrideUserInterfaceStyle = style
        }
    }
}
