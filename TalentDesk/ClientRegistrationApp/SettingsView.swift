import SwiftUI

struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var settingsStore

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var iosVersion: String {
        UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }

    private var deviceModel: String {
        UIDevice.current.name
    }

    var body: some View {
        NavigationStack {
            Form {
                // Appearance
                Section {
                    @Bindable var settings = settingsStore
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                } footer: {
                    Text("Choose Light, Dark, or follow your device setting.")
                }

                // About
                Section {
                    LabeledContent("App Version", value: "\(appVersion) (\(buildNumber))")
                    LabeledContent("iOS Version", value: iosVersion)
                    LabeledContent("Device", value: deviceModel)
                } header: {
                    Label("About", systemImage: "info.circle.fill")
                }

                // App info
                Section {
                    VStack(spacing: 6) {
                        Image(systemName: "briefcase.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                        Text("Talent Desk")
                            .font(.headline)
                        Text("Track opportunities, manage clients, and visualize your freelance career.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
