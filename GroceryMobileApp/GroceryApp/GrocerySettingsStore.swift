import SwiftUI
import Observation

enum GroceryAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }

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
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                UserDefaults.standard.set(appearance.rawValue, forKey: "groceryAppearance")
            }
        }
    }
    var notificationSettings = NotificationSettingsDTO.defaults
    var isLoadingNotificationSettings = false
    var notificationSettingsError: String?

    init() {
        let raw = UserDefaults.standard.string(forKey: "groceryAppearance") ?? GroceryAppearance.system.rawValue
        appearance = GroceryAppearance(rawValue: raw) ?? .system
        notificationSettings = Self.loadCachedNotificationSettings()
    }

    func loadNotificationSettings() async {
        guard APIClient.shared.isAuthenticated else { return }
        isLoadingNotificationSettings = true
        notificationSettingsError = nil
        defer { isLoadingNotificationSettings = false }

        do {
            let settings: NotificationSettingsDTO = try await APIClient.shared.get("/api/user-settings/notifications")
            notificationSettings = settings
            cacheNotificationSettings(settings)
        } catch {
            notificationSettingsError = error.localizedDescription
            print("⚠️ Failed to load notification settings: \(error)")
        }
    }

    func updateNotificationSettings(_ settings: NotificationSettingsDTO) {
        notificationSettings = settings
        cacheNotificationSettings(settings)
        Task { await saveNotificationSettings(settings) }
    }

    private func saveNotificationSettings(_ settings: NotificationSettingsDTO) async {
        guard APIClient.shared.isAuthenticated else { return }

        do {
            let saved: NotificationSettingsDTO = try await APIClient.shared.put(
                "/api/user-settings/notifications",
                body: settings
            )
            notificationSettings = saved
            cacheNotificationSettings(saved)
            notificationSettingsError = nil
        } catch {
            notificationSettingsError = error.localizedDescription
            print("⚠️ Failed to save notification settings: \(error)")
        }
    }

    private static func loadCachedNotificationSettings() -> NotificationSettingsDTO {
        guard let data = UserDefaults.standard.data(forKey: "groceryNotificationSettings"),
              let settings = try? JSONDecoder().decode(NotificationSettingsDTO.self, from: data) else {
            return .defaults
        }
        return settings
    }

    private func cacheNotificationSettings(_ settings: NotificationSettingsDTO) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: "groceryNotificationSettings")
    }
}
