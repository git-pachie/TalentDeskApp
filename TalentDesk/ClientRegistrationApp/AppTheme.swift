import SwiftUI

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@Observable
final class AppSettingsStore {
    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance")
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "appAppearance") ?? AppAppearance.system.rawValue
        appearance = AppAppearance(rawValue: raw) ?? .system
    }
}

enum AppTheme {
    // MARK: - Core palette
    static let accent = Color(red: 0.25, green: 0.48, blue: 1.0)
    static let accentPressed = Color(red: 0.20, green: 0.40, blue: 0.88)
    static let surface = Color(.systemBackground)
    static let secondarySurface = Color(.secondarySystemGroupedBackground)
    static let darkText = Color(.label)
    static let subtitleText = Color(.secondaryLabel)
    static let mutedText = Color(.tertiaryLabel)

    // MARK: - Onboarding palette
    static let onboardingTop = Color(red: 0.10, green: 0.11, blue: 0.26)
    static let onboardingBottom = Color(red: 0.06, green: 0.07, blue: 0.16)
    static let glowPink = Color(red: 0.90, green: 0.32, blue: 0.70)
    static let glowPurple = Color(red: 0.60, green: 0.48, blue: 0.98)
    static let glowBlue = Color(red: 0.42, green: 0.60, blue: 1.0)
}

// MARK: - Onboarding background

struct AppOnboardingBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.onboardingTop, AppTheme.onboardingBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(AppTheme.glowPurple.opacity(0.5))
                .frame(width: 180, height: 180)
                .blur(radius: 70)
                .offset(x: -100, y: -200)
            Circle()
                .fill(AppTheme.glowPink.opacity(0.4))
                .frame(width: 160, height: 160)
                .blur(radius: 70)
                .offset(x: 100, y: 0)
            Circle()
                .fill(AppTheme.glowBlue.opacity(0.35))
                .frame(width: 140, height: 140)
                .blur(radius: 60)
                .offset(x: -20, y: 180)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass card (onboarding only)

struct AppGlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

// MARK: - Button styles

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? AppTheme.accentPressed : AppTheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(configuration.isPressed ? 0.7 : 0.85))
            .foregroundStyle(AppTheme.darkText)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Card modifier for dashboard

struct DashboardCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(AppTheme.secondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func dashboardCard() -> some View {
        modifier(DashboardCard())
    }
}
