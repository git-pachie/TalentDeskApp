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
        let raw = UserDefaults.standard.string(forKey: "appAppearance") ?? AppAppearance.dark.rawValue
        appearance = AppAppearance(rawValue: raw) ?? .system
    }
}

enum AppTheme {
    // MARK: - Core palette (adaptive light/dark)
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.87, blue: 0.72, alpha: 1)
            : UIColor(red: 0.05, green: 0.55, blue: 0.45, alpha: 1)
    })
    static let accentPressed = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.74, blue: 0.62, alpha: 1)
            : UIColor(red: 0.03, green: 0.45, blue: 0.37, alpha: 1)
    })

    // Adaptive colors using UIColor dynamic provider
    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1)
            : UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
    })

    static let secondarySurface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.13, blue: 0.18, alpha: 1)
            : UIColor.white
    })

    static let cardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.08)
    })

    static let darkText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1)
    })

    static let subtitleText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.7)
            : UIColor.black.withAlphaComponent(0.55)
    })

    static let mutedText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.45)
            : UIColor.black.withAlphaComponent(0.35)
    })

    // MARK: - Onboarding palette (always dark)
    static let onboardingTop = Color(red: 0.07, green: 0.09, blue: 0.15)
    static let onboardingBottom = Color(red: 0.04, green: 0.05, blue: 0.10)
    static let glowMint = Color(red: 0.18, green: 0.87, blue: 0.72)
    static let glowTeal = Color(red: 0.12, green: 0.70, blue: 0.65)
    static let glowBlue = Color(red: 0.20, green: 0.50, blue: 0.80)

    // MARK: - Stat colors
    static let statBlue = Color(red: 0.30, green: 0.55, blue: 1.0)
    static let statOrange = Color(red: 1.0, green: 0.60, blue: 0.25)
    static let statGreen = Color(red: 0.18, green: 0.87, blue: 0.72)
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
                .fill(AppTheme.glowMint.opacity(0.25))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: -100, y: -220)
            Circle()
                .fill(AppTheme.glowTeal.opacity(0.20))
                .frame(width: 160, height: 160)
                .blur(radius: 70)
                .offset(x: 120, y: 20)
            Circle()
                .fill(AppTheme.glowBlue.opacity(0.15))
                .frame(width: 140, height: 140)
                .blur(radius: 60)
                .offset(x: -20, y: 200)
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
            .background(AppTheme.secondarySurface.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
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
            .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.secondarySurface.opacity(configuration.isPressed ? 0.9 : 0.7))
            .foregroundStyle(AppTheme.darkText)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

// MARK: - Card modifier for dashboard

struct DashboardCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(AppTheme.secondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func dashboardCard() -> some View {
        modifier(DashboardCard())
    }
}

// MARK: - Reusable screen header

struct AppScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    AppTheme.accent.opacity(isLight ? 0.80 : 0.6),
                    AppTheme.accent.opacity(isLight ? 0.65 : 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(isLight ? 0.03 : 0.08))
                .frame(width: 120, height: 120)
                .offset(x: -30, y: -40)
            Circle()
                .fill(.white.opacity(isLight ? 0.02 : 0.06))
                .frame(width: 80, height: 80)
                .offset(x: 260, y: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(isLight ? AppTheme.darkText : .white)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(isLight ? AppTheme.subtitleText : .white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(height: 140)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24
            )
        )
    }
}
