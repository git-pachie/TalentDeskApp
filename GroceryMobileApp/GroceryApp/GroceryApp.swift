import SwiftUI

@main
struct GroceryApp: App {
    @State private var settingsStore = GrocerySettingsStore()
    @State private var favoritesStore = FavoritesStore()
    @State private var cartStore = CartStore()

    var body: some Scene {
        WindowGroup {
            ThemeRoot(settingsStore: settingsStore, favoritesStore: favoritesStore, cartStore: cartStore)
        }
    }
}

struct ThemeRoot: View {
    let settingsStore: GrocerySettingsStore
    let favoritesStore: FavoritesStore
    let cartStore: CartStore

    var body: some View {
        RootTabView()
            .environment(settingsStore)
            .environment(favoritesStore)
            .environment(cartStore)
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
