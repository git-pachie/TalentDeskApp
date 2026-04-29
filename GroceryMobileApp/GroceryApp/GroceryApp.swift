import SwiftUI

@main
struct GroceryApp: App {
    @State private var settingsStore = GrocerySettingsStore()
    @State private var favoritesStore = FavoritesStore()
    @State private var cartStore = CartStore()
    @State private var authStore = AuthStore()
    @State private var productStore = ProductStore()

    var body: some Scene {
        WindowGroup {
            ThemeRoot(
                settingsStore: settingsStore,
                favoritesStore: favoritesStore,
                cartStore: cartStore,
                authStore: authStore,
                productStore: productStore
            )
        }
    }
}

struct ThemeRoot: View {
    let settingsStore: GrocerySettingsStore
    let favoritesStore: FavoritesStore
    let cartStore: CartStore
    let authStore: AuthStore
    let productStore: ProductStore

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                RootTabView()
            } else {
                LoginView()
            }
        }
        .environment(settingsStore)
        .environment(favoritesStore)
        .environment(cartStore)
        .environment(authStore)
        .environment(productStore)
        .task(id: settingsStore.appearance) {
            setWindowStyle(settingsStore.appearance.uiStyle)
        }
        .task(id: authStore.isAuthenticated) {
            if authStore.isAuthenticated {
                // Load data from server on login
                await productStore.loadHome()
                await cartStore.loadFromServer()
                await favoritesStore.loadFromServer()
            }
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
