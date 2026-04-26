import SwiftUI

struct AppSplashView: View {
    @Bindable var sessionStore: AppSessionStore
    @State private var animate = false

    var body: some View {
        ZStack {
            AppOnboardingBackground()

            VStack(spacing: 28) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animate ? 1.06 : 0.92)

                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(spacing: 8) {
                    Text("You're all set")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Track opportunities, manage clients,\nand visualize your progress.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button("Enter App") {
                        sessionStore.finishSplash()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())

                    Button("Maybe Later") {
                        sessionStore.finishSplash()
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        .task {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                animate = true
            }
            try? await Task.sleep(for: .seconds(2.5))
            guard sessionStore.launchStage == .splash else { return }
            sessionStore.finishSplash()
        }
    }
}

#Preview {
    let store = AppSessionStore()
    store.launchStage = .splash
    return AppSplashView(sessionStore: store)
}
