import Foundation
import Observation
import UIKit
import Darwin

@Observable
final class AuthStore {
    var currentUser: UserDTO?
    var isAuthenticated: Bool = false
    var isLoading = false
    var errorMessage: String?
    var requiresEmailVerification: Bool = false
    var pendingVerificationEmail: String = ""
    private let deviceGuidKey = "device_guid"

    init() {
        // Restore session from UserDefaults if token exists and is not expired
        isAuthenticated = APIClient.shared.isAuthenticated
        if isAuthenticated,
           let data = UserDefaults.standard.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(UserDTO.self, from: data) {
            currentUser = user
        } else if !APIClient.shared.isAuthenticated {
            // Token expired — clear stale user data
            APIClient.shared.clearToken()
            UserDefaults.standard.removeObject(forKey: "current_user")
        }

        // Listen for 401 from any API call — auto-logout
        NotificationCenter.default.addObserver(
            forName: .apiUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSessionExpired()
        }
    }

    private func handleSessionExpired() {
        guard isAuthenticated else { return } // already logged out
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "current_user")
        errorMessage = "Your session has expired. Please log in again."
        print("⚠️ [Auth] Session expired — redirecting to login")
    }

    func refreshCurrentUser() async {
        guard APIClient.shared.isAuthenticated else {
            handleSessionExpired()
            return
        }

        do {
            let user: UserDTO = try await APIClient.shared.get("/api/auth/me")
            currentUser = user
            saveUser(user)
            isAuthenticated = true
            if user.isEmailVerified == false {
                pendingVerificationEmail = user.email
                requiresEmailVerification = true
            } else {
                pendingVerificationEmail = ""
                requiresEmailVerification = false
            }
            print("✅ [Auth] Current user refreshed: \(user.fullName) (\(user.email))")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("⚠️ [Auth] Failed to refresh current user: \(error.localizedDescription)")
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ [Auth] Failed to refresh current user: \(error)")
        }
    }

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        print("🔐 [Login] Attempting login for: \(email)")
        print("🔐 [Login] API URL: \(APIConfig.baseURL)/api/auth/login")

        do {
            let response: AuthResponse = try await APIClient.shared.post(
                "/api/auth/login",
                body: LoginRequest(
                    email: email,
                    password: password,
                    deviceGuid: deviceGuid,
                    osVersion: osVersion,
                    hardwareVersion: hardwareVersion,
                    pushToken: PushNotificationManager.shared.deviceToken,
                    platform: "iOS"
                )
            )

            print("🔐 [Login] Response received — success: \(response.success)")
            if let user = response.user {
                print("🔐 [Login] User: \(user.fullName) (\(user.email))")
            }
            if let errors = response.errors, !errors.isEmpty {
                print("🔐 [Login] Errors: \(errors)")
            }

            if response.success, let token = response.token {
                APIClient.shared.setToken(token)
                currentUser = response.user
                saveUser(response.user)
                isAuthenticated = true
                requiresEmailVerification = false
                Task { await syncDeviceRegistration() }
                print("✅ [Login] SUCCESS — token saved, user: \(response.user?.fullName ?? "nil")")
                return true
            } else if response.requiresEmailVerification == true {
                pendingVerificationEmail = email
                requiresEmailVerification = true
                errorMessage = nil
                print("📧 [Login] Email verification required for: \(email)")
                return false
            } else {
                errorMessage = response.errors?.first ?? "Login failed"
                print("❌ [Login] FAILED — \(errorMessage ?? "unknown")")
                return false
            }
        } catch let error as APIError {
            switch error {
            case .badRequest(let msg):
                // Login returned 400 — wrong credentials or unverified
                errorMessage = msg
            default:
                errorMessage = error.localizedDescription
            }
            print("❌ [Login] APIError — \(error.localizedDescription)")
            return false
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [Login] Error — \(error)")
            return false
        }
    }

    func register(firstName: String, lastName: String, email: String, password: String, phone: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: AuthResponse = try await APIClient.shared.post(
                "/api/auth/register",
                body: RegisterRequest(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password,
                    phoneNumber: phone,
                    deviceGuid: deviceGuid,
                    osVersion: osVersion,
                    hardwareVersion: hardwareVersion,
                    pushToken: PushNotificationManager.shared.deviceToken,
                    platform: "iOS"
                )
            )

            if response.success, let token = response.token {
                APIClient.shared.setToken(token)
                currentUser = response.user
                saveUser(response.user)
                isAuthenticated = true
                Task { await syncDeviceRegistration() }
                return true
            } else if response.requiresEmailVerification == true {
                pendingVerificationEmail = email
                requiresEmailVerification = true
                errorMessage = nil
                print("📧 [Register] Email verification required for: \(email)")
                return true
            } else {
                errorMessage = response.errors?.first ?? "Registration failed"
                return false
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Sends a verification code to the current user's email (must be logged in).
    func sendEmailVerificationCode() async -> Bool {
        guard APIClient.shared.isAuthenticated else { return false }
        do {
            struct Resp: Decodable { let message: String? }
            let _: Resp = try await APIClient.shared.post("/api/auth/send-email-code", body: EmptyBody())
            print("📧 [Auth] Email verification code sent")
            return true
        } catch {
            print("⚠️ [Auth] Failed to send email code: \(error)")
            return false
        }
    }

    /// Sends a verification code to the current user's phone number (must be logged in).
    func sendPhoneVerificationCode() async -> Bool {
        guard APIClient.shared.isAuthenticated else { return false }
        guard let phoneNumber = currentUser?.phoneNumber, !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No mobile number found on your account."
            return false
        }

        do {
            struct Resp: Decodable { let message: String? }
            let _: Resp = try await APIClient.shared.post("/api/auth/send-phone-code", body: EmptyBody())
            print("📱 [Auth] Phone verification code sent")
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("⚠️ [Auth] Failed to send phone code: \(error.localizedDescription)")
            return false
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ [Auth] Failed to send phone code: \(error)")
            return false
        }
    }

    /// Verifies email using a code — used from Profile (user already logged in).
    func verifyEmailFromProfile(code: String) async -> Bool {
        guard let email = currentUser?.email else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: VerifyEmailResponse = try await APIClient.shared.post(
                "/api/auth/verify-email",
                body: VerifyEmailRequest(email: email, code: code)
            )
            if response.success {
                // Refresh user profile to get updated verification status
                await refreshCurrentUser()
                print("✅ [Auth] Email verified from profile")
                return true
            } else {
                errorMessage = response.error ?? "Incorrect code. Please try again."
                return false
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Verifies phone using a code from Profile (user already logged in).
    func verifyPhoneFromProfile(code: String) async -> Bool {
        guard let phoneNumber = currentUser?.phoneNumber,
              !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No mobile number found on your account."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: VerifyPhoneResponse = try await APIClient.shared.post(
                "/api/auth/verify-phone",
                body: VerifyPhoneRequest(code: code)
            )
            if response.success {
                await refreshCurrentUser()
                print("✅ [Auth] Phone verified from profile")
                return true
            } else {
                errorMessage = response.error ?? "Incorrect code. Please try again."
                return false
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        APIClient.shared.clearToken()
        currentUser = nil
        isAuthenticated = false
        requiresEmailVerification = false
        pendingVerificationEmail = ""
        UserDefaults.standard.removeObject(forKey: "current_user")
    }

    func verifyEmail(code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: VerifyEmailResponse = try await APIClient.shared.post(
                "/api/auth/verify-email",
                body: VerifyEmailRequest(email: pendingVerificationEmail, code: code)
            )
            if response.success, let token = response.token {
                APIClient.shared.setToken(token)
                // Fetch full user profile now that we have a valid token
                await refreshCurrentUser()
                isAuthenticated = true
                requiresEmailVerification = false
                pendingVerificationEmail = ""
                print("✅ [EmailVerify] Verified successfully")
                return true
            } else {
                errorMessage = response.error ?? "Verification failed."
                return false
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func saveUser(_ user: UserDTO?) {
        guard let user else { return }
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "current_user")
        }
    }

    private func syncDeviceRegistration() async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            struct Resp: Decodable { let success: Bool? }
            let _: Resp = try await APIClient.shared.post(
                "/api/user-devices/register",
                body: RegisterDeviceRequest(
                    deviceGuid: deviceGuid,
                    osVersion: osVersion,
                    hardwareVersion: hardwareVersion,
                    pushToken: PushNotificationManager.shared.deviceToken,
                    platform: "iOS"
                )
            )
        } catch {
            // best-effort
        }
    }

    private var deviceGuid: String {
        if let existing = UserDefaults.standard.string(forKey: deviceGuidKey), !existing.isEmpty {
            return existing
        }

        let newValue = UUID().uuidString
        UserDefaults.standard.set(newValue, forKey: deviceGuidKey)
        return newValue
    }

    private var osVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private var hardwareVersion: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier.append(String(UnicodeScalar(UInt8(value))))
        }
    }
}

// Used for POST requests with no body
private struct EmptyBody: Encodable {}
