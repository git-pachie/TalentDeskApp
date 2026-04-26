import Foundation
import Observation

struct AppUserProfile: Codable, Equatable {
    var name: String
    var email: String
    var mobile: String
}

enum AppLaunchStage: Equatable {
    case registration
    case splash
    case ready
}

@Observable
final class AppSessionStore {
    var launchStage: AppLaunchStage = .registration
    var profile: AppUserProfile?

    private let storageURL: URL

    init() {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let directory = baseDirectory.appendingPathComponent("ClientRegistrationApp", isDirectory: true)
        storageURL = directory.appendingPathComponent("app-user.json")

        loadProfile()
    }

    func registerUser(_ profile: AppUserProfile) {
        self.profile = profile
        launchStage = .splash
        saveProfile()
    }

    func finishSplash() {
        launchStage = .ready
    }

    private func loadProfile() {
        do {
            let data = try Data(contentsOf: storageURL)
            profile = try JSONDecoder().decode(AppUserProfile.self, from: data)
            launchStage = .ready
        } catch CocoaError.fileReadNoSuchFile {
            profile = nil
            launchStage = .registration
        } catch {
            profile = nil
            launchStage = .registration
            NSLog("Failed to load app user profile: \(error.localizedDescription)")
        }
    }

    private func saveProfile() {
        guard let profile else { return }

        do {
            let directory = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(profile)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            NSLog("Failed to save app user profile: \(error.localizedDescription)")
        }
    }
}
