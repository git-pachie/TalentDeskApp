import SwiftUI
import Observation

enum GroceryAppearance: String, CaseIterable {
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

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}

@Observable
final class GrocerySettingsStore {
    var appearance: GroceryAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "groceryAppearance")
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "groceryAppearance") ?? GroceryAppearance.system.rawValue
        appearance = GroceryAppearance(rawValue: raw) ?? .system
    }
}
