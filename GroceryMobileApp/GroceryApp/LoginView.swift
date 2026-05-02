import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var showEmailVerificationAlert = false
    @State private var navigateToVerification = false

    var body: some View {
        NavigationStack {
            ZStack {
                loginBackdrop

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer().frame(height: 28)

                        VStack(spacing: 14) {
                            GroceryIconView(size: 92)

                            Text("GroceryApp")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 0.11, green: 0.23, blue: 0.14))

                            Text("Fresh picks, faster delivery, and a smoother way to stock your kitchen.")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(Color(red: 0.28, green: 0.34, blue: 0.25).opacity(0.86))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)
                        }

                        VStack(spacing: 18) {
                            HStack(spacing: 12) {
                                loginFeatureBadge(icon: "leaf.fill", text: "Fresh daily")
                                loginFeatureBadge(icon: "clock.fill", text: "Fast checkout")
                                loginFeatureBadge(icon: "truck.box.fill", text: "Local delivery")
                            }

                            VStack(spacing: 18) {
                                loginInputField(
                                    label: "Email",
                                    icon: "envelope.fill",
                                    placeholder: "admin@groceryapp.com",
                                    text: $email,
                                    isSecure: false
                                )

                                loginInputField(
                                    label: "Password",
                                    icon: "lock.fill",
                                    placeholder: "Password",
                                    text: $password,
                                    isSecure: true
                                )

                                if let error = authStore.errorMessage, !authStore.requiresEmailVerification {
                                    Text(error)
                                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                                        .foregroundStyle(GroceryTheme.badge)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                }

                                Button {
                                    Task {
                                        print("🔘 [LoginView] Sign In tapped — email: \(email)")
                                        let success = await authStore.login(email: email, password: password)
                                        print("🔘 [LoginView] Login result: \(success ? "SUCCESS" : "FAILED")")
                                        if !success && authStore.requiresEmailVerification {
                                            showEmailVerificationAlert = true
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        if authStore.isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        Text("Sign In")
                                            .font(.system(.title3, design: .rounded, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(isFormValid ? GroceryTheme.primary : Color(.systemGray3))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .shadow(color: GroceryTheme.primary.opacity(0.24), radius: 16, y: 10)
                                }
                                .disabled(!isFormValid || authStore.isLoading)

                                Button {
                                    showingRegister = true
                                } label: {
                                    HStack(spacing: 5) {
                                        Text("Don't have an account?")
                                        Text("Sign Up")
                                            .fontWeight(.bold)
                                            .foregroundStyle(GroceryTheme.primary)
                                    }
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(GroceryTheme.subtitle)
                                }
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.65), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.10), radius: 28, y: 14)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
            .background(GroceryTheme.background)
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $navigateToVerification) {
                EmailVerificationView()
            }
            .alert("Email Verification Required", isPresented: $showEmailVerificationAlert) {
                Button("Verify Now") {
                    navigateToVerification = true
                }
                Button("Cancel", role: .cancel) {
                    authStore.requiresEmailVerification = false
                }
            } message: {
                Text("Your email address needs to be verified before you can log in. A 4-digit code has been sent to \(authStore.pendingVerificationEmail).")
            }
        }
    }

    private var loginBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.95, blue: 0.86),
                    Color(red: 0.90, green: 0.97, blue: 0.88),
                    Color(red: 0.83, green: 0.95, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image(systemName: "basket.fill")
                .font(.system(size: 200))
                .foregroundStyle(Color.white.opacity(0.18))
                .rotationEffect(.degrees(-18))
                .offset(x: -120, y: -260)

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 190))
                .foregroundStyle(GroceryTheme.primary.opacity(0.16))
                .offset(x: 150, y: -190)

            Image(systemName: "carrot.fill")
                .font(.system(size: 180))
                .foregroundStyle(Color.orange.opacity(0.16))
                .rotationEffect(.degrees(24))
                .offset(x: 125, y: 260)

            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 220))
                .foregroundStyle(Color(red: 0.24, green: 0.50, blue: 0.26).opacity(0.10))
                .offset(x: -120, y: 250)
        }
    }

    private func loginFeatureBadge(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.75))
            .foregroundStyle(Color(red: 0.18, green: 0.35, blue: 0.18))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func loginInputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(GroceryTheme.subtitle)

            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(GroceryTheme.primary)

                if isSecure {
                    SecureField(placeholder, text: text)
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: text)
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color.white.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.88), lineWidth: 1)
            )
        }
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
}

// MARK: - Register View

struct RegisterView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phone = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    inputField(label: "First Name", placeholder: "John", text: $firstName)
                    inputField(label: "Last Name", placeholder: "Doe", text: $lastName)
                    inputField(label: "Email", placeholder: "john@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(GroceryTheme.muted)
                        SecureField("Min 6 characters", text: $password)
                            .font(.system(.subheadline, design: .rounded))
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    inputField(label: "Phone (optional)", placeholder: "+1 555 123 4567", text: $phone)
                        .keyboardType(.phonePad)

                    if let error = authStore.errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(GroceryTheme.badge)
                    }

                    Button {
                        Task {
                            let success = await authStore.register(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                password: password,
                                phone: phone.isEmpty ? nil : phone
                            )
                            if success { dismiss() }
                        }
                    } label: {
                        HStack {
                            if authStore.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("Create Account")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? GroceryTheme.primary : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!isFormValid || authStore.isLoading)
                }
                .padding(24)
            }
            .background(GroceryTheme.background)
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }

    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(GroceryTheme.muted)
            TextField(placeholder, text: text)
                .font(.system(.subheadline, design: .rounded))
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthStore())
}
