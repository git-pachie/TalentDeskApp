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

    var body: some View {
        ZStack {
            Image("LaunchLoading")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Text("SheraMart")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 12)

                Text(apiReachable ? "Connection confirmed. Preparing your groceries..." : "Checking API connectivity...")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .opacity(pulse ? 1.0 : 0.55)

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
