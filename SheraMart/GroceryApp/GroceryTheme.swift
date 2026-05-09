import SwiftUI

enum GroceryTheme {
    // Primary green
    static let primary = Color(red: 0.329, green: 0.690, blue: 0.314)
    static let primaryLight = Color(red: 0.329, green: 0.690, blue: 0.314).opacity(0.12)

    static let primaryBanner = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.28, blue: 0.18, alpha: 1)
            : UIColor(red: 0.85, green: 0.95, blue: 0.85, alpha: 1)
    })

    // Text — adaptive
    static let title = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    })

    static let subtitle = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.6)
            : UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
    })

    static let muted = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.4)
            : UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1)
    })

    // Surfaces — adaptive
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
            : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
    })

    static let card = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            : .white
    })

    static let cardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor.black.withAlphaComponent(0.06)
    })

    // Discount badge
    static let badge = Color(red: 0.85, green: 0.22, blue: 0.22)
}
