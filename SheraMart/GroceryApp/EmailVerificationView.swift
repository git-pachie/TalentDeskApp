import SwiftUI

struct EmailVerificationView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss
    @State private var digits: [String] = ["", "", "", ""]
    @FocusState private var focusedIndex: Int?
    @State private var isSubmitting = false
    @State private var statusMessage: String?
    @State private var didRequestCodeOnAppear = false

    private var code: String { digits.joined() }
    private var isComplete: Bool { digits.allSatisfy { $0.count == 1 } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(GroceryTheme.primaryLight)
                            .frame(width: 90, height: 90)
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(GroceryTheme.primary)
                    }

                    VStack(spacing: 8) {
                        Text("Verify Your Email")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(GroceryTheme.title)

                        Text("We sent a 4-digit code to")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GroceryTheme.muted)

                        Text(authStore.pendingVerificationEmail)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.primary)
                    }
                    .multilineTextAlignment(.center)

                    // OTP boxes
                    HStack(spacing: 14) {
                        ForEach(0..<4, id: \.self) { index in
                            OTPBox(
                                digit: $digits[index],
                                isFocused: focusedIndex == index
                            )
                            .focused($focusedIndex, equals: index)
                            .onChange(of: digits[index]) { _, newVal in
                                handleDigitChange(index: index, value: newVal)
                            }
                        }
                    }

                    // Error
                    if let error = authStore.errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(GroceryTheme.badge)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(GroceryTheme.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Verify button
                    Button {
                        Task { await submitCode() }
                    } label: {
                        HStack {
                            if authStore.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("Verify Email")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isComplete ? GroceryTheme.primary : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!isComplete || authStore.isLoading)

                    // Resend
                    Button {
                        Task { await resendCode() }
                    } label: {
                        Text("Resend Code")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(GroceryTheme.primary)
                    }

                    Button {
                        goToLogin()
                    } label: {
                        Text("Log In Instead")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .foregroundStyle(GroceryTheme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(GroceryTheme.background)
            .navigationBarHidden(true)
            .onAppear {
                focusedIndex = 0
            }
            .task {
                guard authStore.isAuthenticated, !didRequestCodeOnAppear else { return }
                didRequestCodeOnAppear = true
                let sent = await authStore.sendEmailVerificationCode()
                if sent {
                    statusMessage = "A new verification code has been sent."
                }
            }
        }
    }

    // MARK: - Digit input handling

    private func handleDigitChange(index: Int, value: String) {
        // Keep only last character if multiple pasted
        if value.count > 1 {
            let filtered = value.filter { $0.isNumber }
            // Handle paste of full 4-digit code
            if filtered.count >= 4 {
                for i in 0..<4 {
                    digits[i] = String(filtered[filtered.index(filtered.startIndex, offsetBy: i)])
                }
                focusedIndex = nil
                return
            }
            digits[index] = String(filtered.suffix(1))
        }

        // Only allow digits
        let filtered = value.filter { $0.isNumber }
        if filtered != value { digits[index] = filtered; return }

        // Auto-advance
        if !value.isEmpty && index < 3 {
            focusedIndex = index + 1
        }

        // Auto-submit when all filled
        if isComplete {
            focusedIndex = nil
            Task { await submitCode() }
        }
    }

    private func submitCode() async {
        guard isComplete else { return }
        let _ = await authStore.verifyEmail(code: code)
        if !authStore.isAuthenticated {
            // Clear boxes on failure so user can retry
            digits = ["", "", "", ""]
            focusedIndex = 0
        }
    }

    private func resendCode() async {
        authStore.errorMessage = nil
        statusMessage = nil
        digits = ["", "", "", ""]
        focusedIndex = 0

        if authStore.isAuthenticated {
            let sent = await authStore.sendEmailVerificationCode()
            statusMessage = sent
                ? "A new verification code has been sent."
                : "Unable to send a new code. Please try again."
        } else {
            authStore.errorMessage = "A new code will be sent when you log in again."
        }
    }

    private func goToLogin() {
        authStore.logout()
        dismiss()
    }
}

// MARK: - OTP Box

private struct OTPBox: View {
    @Binding var digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isFocused ? GroceryTheme.primary : Color(.systemGray4),
                            lineWidth: isFocused ? 2 : 1
                        )
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

#Preview {
    EmailVerificationView()
        .environment({
            let s = AuthStore()
            s.pendingVerificationEmail = "user@example.com"
            s.requiresEmailVerification = true
            return s
        }())
}
