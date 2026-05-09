import SwiftUI

@main
struct GroceryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settingsStore = GrocerySettingsStore()
    @State private var favoritesStore = FavoritesStore()
    @State private var cartStore = CartStore()
    @State private var authStore = AuthStore()
    @State private var productStore = ProductStore()
    @State private var navigationStore = AppNavigationStore()

    var body: some Scene {
        WindowGroup {
            ThemeRoot(
                settingsStore: settingsStore,
                favoritesStore: favoritesStore,
                cartStore: cartStore,
                authStore: authStore,
                productStore: productStore,
                navigationStore: navigationStore
            )
        }
    }
}

struct ThemeRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBootstrapping = true
    @State private var apiReachable = false

    let settingsStore: GrocerySettingsStore
    let favoritesStore: FavoritesStore
    let cartStore: CartStore
    let authStore: AuthStore
    let productStore: ProductStore
    let navigationStore: AppNavigationStore

    var body: some View {
        Group {
            if isBootstrapping {
                LaunchSplashView(apiReachable: apiReachable)
            } else {
                Group {
                    if authStore.requiresEmailVerification {
                        EmailVerificationView()
                    } else if authStore.isAuthenticated {
                        RootTabView()
                    } else {
                        LoginView()
                    }
                }
            }
        }
        .environment(settingsStore)
        .environment(favoritesStore)
        .environment(cartStore)
        .environment(authStore)
        .environment(productStore)
        .environment(navigationStore)
        .task {
            await bootstrapApplication()
            await PushNotificationManager.shared.requestAuthorizationAndRegister()
        }
        .task(id: settingsStore.appearance) {
            setWindowStyle(settingsStore.appearance.uiStyle)
        }
        .task(id: authStore.isAuthenticated) {
            if authStore.isAuthenticated {
                await authStore.refreshCurrentUser()
                // Load data from server on login
                await productStore.loadHome()
                await cartStore.loadFromServer()
                await favoritesStore.loadFromServer()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, authStore.isAuthenticated else { return }
            Task {
                await authStore.refreshCurrentUser()
            }
        }
    }

    @MainActor
    private func bootstrapApplication() async {
        guard isBootstrapping else { return }

        async let connectivityCheck = APIClient.shared.checkConnectivity()
        let minimumDelay = Task {
            try? await Task.sleep(for: .milliseconds(1400))
        }

        let reachable = await connectivityCheck
        _ = await minimumDelay.value

        apiReachable = reachable
        isBootstrapping = false
    }

    private func setWindowStyle(_ style: UIUserInterfaceStyle) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        UIView.animate(withDuration: 0.3) {
            window.overrideUserInterfaceStyle = style
        }
    }
}

private struct LaunchSplashView: View {
    let apiReachable: Bool
    @State private var pulse = false
    @State private var drift = false
    @State private var rotateRing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.95, blue: 0.86),
                    Color(red: 0.90, green: 0.97, blue: 0.88),
                    Color(red: 0.83, green: 0.95, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image(systemName: "leaf.fill")
                .font(.system(size: 170))
                .foregroundStyle(Color.white.opacity(0.24))
                .rotationEffect(.degrees(drift ? -14 : -5))
                .offset(x: -118, y: -220)

            Image(systemName: "carrot.fill")
                .font(.system(size: 150))
                .foregroundStyle(Color.orange.opacity(0.18))
                .rotationEffect(.degrees(drift ? 12 : 20))
                .offset(x: 128, y: -170)

            Image(systemName: "basket.fill")
                .font(.system(size: 220))
                .foregroundStyle(Color(red: 0.24, green: 0.50, blue: 0.26).opacity(0.10))
                .offset(x: -110, y: 245)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.30))
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    Circle()
                        .stroke(Color.white.opacity(0.60), lineWidth: 3)
                        .frame(width: 178, height: 178)
                        .rotationEffect(.degrees(rotateRing ? 360 : 0))

                    GroceryIconView(size: 108)
                }

                VStack(spacing: 8) {
                    Text("GroceryApp")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.11, green: 0.22, blue: 0.13))

                    Text(apiReachable ? "Connection confirmed. Preparing your groceries..." : "Checking API connectivity...")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color(red: 0.25, green: 0.34, blue: 0.22).opacity(0.86))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                ProgressView()
                    .tint(Color(red: 0.20, green: 0.50, blue: 0.24))
                    .scaleEffect(1.25)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
                drift = true
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotateRing = true
            }
        }
    }
}
