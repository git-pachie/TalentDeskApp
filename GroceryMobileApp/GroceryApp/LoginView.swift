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
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 40)

                    // Logo
                    GroceryIconView(size: 80)

                    Text("GroceryApp")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(GroceryTheme.primary)

                    Text("Fresh groceries, delivered fast")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)

                    // Form
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(GroceryTheme.muted)
                            TextField("admin@groceryapp.com", text: $email)
                                .font(.system(.subheadline, design: .rounded))
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(GroceryTheme.muted)
                            SecureField("Password", text: $password)
                                .font(.system(.subheadline, design: .rounded))
                                .textContentType(.password)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 4)

                    // Error
                    if let error = authStore.errorMessage, !authStore.requiresEmailVerification {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(GroceryTheme.badge)
                            .multilineTextAlignment(.center)
                    }

                    // Login button
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
                        HStack {
                            if authStore.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Sign In")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? GroceryTheme.primary : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!isFormValid || authStore.isLoading)

                    // Register link
                    Button {
                        showingRegister = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(GroceryTheme.muted)
                            Text("Sign Up")
                                .foregroundStyle(GroceryTheme.primary)
                                .fontWeight(.semibold)
                        }
                        .font(.system(.caption, design: .rounded))
                    }

                    // Skip login
                    Button {
                        // Continue as guest — no token set
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(GroceryTheme.muted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
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
