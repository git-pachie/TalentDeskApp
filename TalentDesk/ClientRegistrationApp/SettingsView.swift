import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var settingsStore
    @Environment(PushNotificationManager.self) private var pushManager

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

                // Push Notifications
                Section {
                    switch pushManager.permissionStatus {
                    case .authorized:
                        Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    case .denied:
                        Label("Notifications Denied", systemImage: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        Text("Enable in Settings → Notifications → Talent Desk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    default:
                        Button("Enable Push Notifications") {
                            pushManager.requestPermission()
                        }
                        .font(.subheadline)
                    }

                    if let token = pushManager.deviceToken {
                        LabeledContent("Device Token") {
                            Text(token)
                                .font(.caption2)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Button("Copy Token") {
                            UIPasteboard.general.string = token
                        }
                        .font(.caption)
                    }

                    if let error = pushManager.registrationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Label("Push Notifications", systemImage: "bell.fill")
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
        .environment(PushNotificationManager())
}
