import SwiftUI

struct AppRegistrationView: View {
    @Bindable var sessionStore: AppSessionStore
    @State private var name = ""
    @State private var email = ""
    @State private var mobile = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        mobile.trimmingCharacters(in: .whitespacesAndNewlines).count >= 7
    }

    var body: some View {
        ZStack {
            AppOnboardingBackground()
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("Welcome to Talent Desk")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        Text("Create your account to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 20)

                    // Form card
                    AppGlassCard {
                        VStack(spacing: 14) {
                            fieldRow(icon: "person", placeholder: "Full Name", text: $name)
                                .textInputAutocapitalization(.words)

                            fieldRow(icon: "envelope", placeholder: "Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            fieldRow(icon: "phone", placeholder: "Mobile", text: $mobile)
                                .keyboardType(.phonePad)

                            Button("Get Started", action: register)
                                .buttonStyle(AppPrimaryButtonStyle())
                                .disabled(!isValid)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedText)
                }
                TextField("", text: text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.darkText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.secondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func register() {
        sessionStore.registerUser(
            AppUserProfile(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                mobile: mobile.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }
}

#Preview {
    AppRegistrationView(sessionStore: AppSessionStore())
}
