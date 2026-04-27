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
        ScrollView {
            VStack(spacing: 0) {
                AppScreenHeader(title: "Settings", subtitle: "Customize your experience")

                VStack(spacing: 16) {
                    // Appearance
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Appearance", systemImage: "paintbrush.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        @Bindable var settings = settingsStore
                        HStack(spacing: 8) {
                            ForEach(AppAppearance.allCases, id: \.self) { mode in
                                Button {
                                    settings.appearance = mode
                                } label: {
                                    Text(mode.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            settings.appearance == mode
                                                ? AppTheme.accent
                                                : AppTheme.surface
                                        )
                                        .foregroundStyle(
                                            settings.appearance == mode
                                                ? Color(red: 0.05, green: 0.07, blue: 0.10)
                                                : AppTheme.subtitleText
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(
                                                    settings.appearance == mode
                                                        ? AppTheme.accent
                                                        : AppTheme.cardBorder,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                        }

                        Text("Choose Light, Dark, or follow your device setting.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dashboardCard()

                    // Push Notifications
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Push Notifications", systemImage: "bell.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        switch pushManager.permissionStatus {
                        case .authorized:
                            Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.statGreen)
                        case .denied:
                            Label("Notifications Denied", systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            Text("Enable in Settings → Notifications → Talent Desk")
                                .font(.caption)
                                .foregroundStyle(AppTheme.mutedText)
                        default:
                            Button("Enable Push Notifications") {
                                pushManager.requestPermission()
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                        }

                        if let token = pushManager.deviceToken {
                            HStack {
                                Text("Device Token")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.subtitleText)
                                Spacer()
                                Text(token)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.mutedText)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Button("Copy Token") {
                                UIPasteboard.general.string = token
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                        }

                        if let error = pushManager.registrationError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dashboardCard()

                    // About
                    VStack(alignment: .leading, spacing: 12) {
                        Label("About", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        infoRow(label: "App Version", value: "\(appVersion) (\(buildNumber))")
                        infoRow(label: "iOS Version", value: iosVersion)
                        infoRow(label: "Device", value: deviceModel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dashboardCard()

                    // App info
                    VStack(spacing: 6) {
                        Image(systemName: "briefcase.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                        Text("Talent Desk")
                            .font(.headline)
                            .foregroundStyle(AppTheme.darkText)
                        Text("Track opportunities, manage clients, and visualize your freelance career.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.subtitleText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .dashboardCard()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(AppTheme.surface)
        .ignoresSafeArea(edges: .top)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtitleText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.darkText)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettingsStore())
        .environment(PushNotificationManager())
        .preferredColorScheme(.dark)
}
