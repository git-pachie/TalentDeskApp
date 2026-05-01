import SwiftUI

struct ProfileView: View {
    @Environment(GrocerySettingsStore.self) private var settingsStore
    @Environment(AuthStore.self) private var authStore
    @State private var showEmailVerifySheet = false
    @State private var isSendingCode = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        GroceryIconView(size: 50)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authStore.currentUser?.fullName ?? "Loading profile")
                                .font(.system(.headline, design: .rounded))
                            Text(authStore.currentUser?.email ?? "Fetching your account")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Appearance
                Section {
                    HStack(spacing: 8) {
                        ForEach(GroceryAppearance.allCases, id: \.self) { mode in
                            Button {
                                print("🎨 Tapped: \(mode.rawValue)")
                                settingsStore.appearance = mode
                                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        for window in scene.windows {
                                            window.overrideUserInterfaceStyle = mode.uiStyle
                                        }
                                    }
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: mode.icon)
                                        .font(.title3)
                                    Text(mode.rawValue)
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    settingsStore.appearance == mode
                                        ? GroceryTheme.primary.opacity(0.15)
                                        : Color(.systemGray6)
                                )
                                .foregroundStyle(
                                    settingsStore.appearance == mode
                                        ? GroceryTheme.primary
                                        : .secondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            settingsStore.appearance == mode
                                                ? GroceryTheme.primary
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                Section("Account") {
                    NavigationLink {
                        OrdersView()
                    } label: {
                        Label("Orders", systemImage: "bag")
                    }
                    NavigationLink {
                        AddressListView()
                    } label: {
                        Label("Addresses", systemImage: "mappin.circle")
                    }
                    NavigationLink {
                        PaymentMethodsView()
                    } label: {
                        Label("Payment Methods", systemImage: "creditcard")
                    }
                    NavigationLink {
                        VouchersView()
                    } label: {
                        Label("Vouchers", systemImage: "ticket")
                    }
                }

                // Verification Status
                Section {
                    verificationRow(
                        title: "Email",
                        value: authStore.currentUser?.email ?? "—",
                        isVerified: authStore.currentUser?.isEmailVerified ?? false,
                        icon: "envelope.fill"
                    ) {
                        Task {
                            isSendingCode = true
                            let sent = await authStore.sendEmailVerificationCode()
                            isSendingCode = false
                            if sent { showEmailVerifySheet = true }
                        }
                    }
                    verificationRow(
                        title: "Mobile",
                        value: authStore.currentUser?.phoneNumber ?? "Not set",
                        isVerified: authStore.currentUser?.isPhoneVerified ?? false,
                        icon: "phone.fill",
                        onVerify: nil // SMS not yet wired
                    )
                } header: {
                    Label("Verification", systemImage: "shield.checkered")
                }
                .sheet(isPresented: $showEmailVerifySheet) {
                    ProfileEmailVerifySheet()
                }

                Section("Settings") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    Label("Help & Support", systemImage: "questionmark.circle")
                }

                Section {
                    Button {
                        authStore.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(GroceryTheme.badge)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await authStore.refreshCurrentUser()
            }
            .refreshable {
                await authStore.refreshCurrentUser()
            }
        }
    }
    @ViewBuilder
    private func verificationRow(title: String, value: String, isVerified: Bool, icon: String, onVerify: (() -> Void)?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(GroceryTheme.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(GroceryTheme.title)
                Text(value)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: isVerified ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(isVerified ? "Verified" : "Unverified")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(isVerified ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isVerified ? Color.green : Color.orange).opacity(0.1))
                .clipShape(Capsule())
                .padding(.top, 2)
            }

            Spacer()

            if !isVerified, let onVerify {
                Button {
                    onVerify()
                } label: {
                    if isSendingCode {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 52, height: 26)
                    } else {
                        Text("Verify")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(GroceryTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSendingCode)
            }
        }
    }
}

#Preview {
    ProfileView()
        .groceryPreviewEnvironment()
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @Environment(GrocerySettingsStore.self) private var settingsStore

    private let options: [NotificationSettingOption] = [
        .init(title: "Marketing & Promotions", keyPath: \.marketingPromotions),
        .init(title: "Product Updates", keyPath: \.productUpdates),
        .init(title: "News & Announcements", keyPath: \.newsAnnouncements),
        .init(title: "Transactions & Billing", keyPath: \.transactionsBilling),
        .init(title: "Alerts & Critical", keyPath: \.alertsCritical),
        .init(title: "Usage & Activity", keyPath: \.usageActivity),
        .init(title: "Account & Security", keyPath: \.accountSecurity),
        .init(title: "Reminders", keyPath: \.reminders),
        .init(title: "Messages & Support", keyPath: \.messagesSupport),
        .init(title: "Personalized Recommendations", keyPath: \.personalizedRecommendations)
    ]

    var body: some View {
        List {
            Section {
                ForEach(options) { option in
                    Toggle(option.title, isOn: binding(for: option.keyPath))
                        .font(.system(.body, design: .rounded))
                }
            } footer: {
                if settingsStore.isLoadingNotificationSettings {
                    Text("Loading preferences...")
                } else if let error = settingsStore.notificationSettingsError {
                    Text("Last update failed: \(error)")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await settingsStore.loadNotificationSettings()
        }
        .refreshable {
            await settingsStore.loadNotificationSettings()
        }
    }

    private func binding(for keyPath: WritableKeyPath<NotificationSettingsDTO, Bool>) -> Binding<Bool> {
        Binding(
            get: { settingsStore.notificationSettings[keyPath: keyPath] },
            set: { newValue in
                var settings = settingsStore.notificationSettings
                settings[keyPath: keyPath] = newValue
                settingsStore.updateNotificationSettings(settings)
            }
        )
    }
}

private struct NotificationSettingOption: Identifiable {
    let title: String
    let keyPath: WritableKeyPath<NotificationSettingsDTO, Bool>
    var id: String { title }
}

// MARK: - Profile Email Verify Sheet

struct ProfileEmailVerifySheet: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss
    @State private var digits: [String] = ["", "", "", ""]
    @FocusState private var focusedIndex: Int?

    private var code: String { digits.joined() }
    private var isComplete: Bool { digits.allSatisfy { $0.count == 1 } }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer().frame(height: 10)

                ZStack {
                    Circle()
                        .fill(GroceryTheme.primaryLight)
                        .frame(width: 80, height: 80)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(GroceryTheme.primary)
                }

                VStack(spacing: 8) {
                    Text("Verify Your Email")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(GroceryTheme.title)
                    Text("Enter the 4-digit code sent to")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                    Text(authStore.currentUser?.email ?? "your email")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.primary)
                }
                .multilineTextAlignment(.center)

                // OTP boxes
                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { index in
                        OTPBoxView(digit: $digits[index], isFocused: focusedIndex == index)
                            .focused($focusedIndex, equals: index)
                            .onChange(of: digits[index]) { _, newVal in
                                handleInput(index: index, value: newVal)
                            }
                    }
                }

                if let error = authStore.errorMessage {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.badge)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if authStore.isLoading { ProgressView().tint(.white) }
                        Text("Verify")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isComplete ? GroceryTheme.primary : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!isComplete || authStore.isLoading)
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.horizontal, 32)
            .background(GroceryTheme.background)
            .navigationTitle("Email Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        authStore.errorMessage = nil
                        dismiss()
                    }
                }
            }
            .onAppear { focusedIndex = 0 }
        }
    }

    private func handleInput(index: Int, value: String) {
        let filtered = value.filter { $0.isNumber }
        if filtered.count >= 4 {
            for i in 0..<4 {
                digits[i] = String(filtered[filtered.index(filtered.startIndex, offsetBy: i)])
            }
            focusedIndex = nil
            Task { await submit() }
            return
        }
        if filtered != value { digits[index] = filtered; return }
        if !value.isEmpty && index < 3 { focusedIndex = index + 1 }
        if isComplete { focusedIndex = nil; Task { await submit() } }
    }

    private func submit() async {
        guard isComplete else { return }
        let success = await authStore.verifyEmailFromProfile(code: code)
        if success {
            dismiss()
        } else {
            digits = ["", "", "", ""]
            focusedIndex = 0
        }
    }
}

// Reusable OTP box (same style as EmailVerificationView)
private struct OTPBoxView: View {
    @Binding var digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isFocused ? GroceryTheme.primary : Color(.systemGray4),
                                lineWidth: isFocused ? 2 : 1)
                )
                .frame(width: 64, height: 72)
            TextField("", text: $digit)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(GroceryTheme.title)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 64, height: 72)
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
