import Foundation
import Observation

@Observable
final class AuthStore {
    var currentUser: UserDTO?
    var isAuthenticated: Bool = false
    var isLoading = false
    var errorMessage: String?

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

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        print("🔐 [Login] Attempting login for: \(email)")
        print("🔐 [Login] API URL: \(APIConfig.baseURL)/api/auth/login")

        do {
            let response: AuthResponse = try await APIClient.shared.post(
                "/api/auth/login",
                body: LoginRequest(email: email, password: password)
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
                print("✅ [Login] SUCCESS — token saved, user: \(response.user?.fullName ?? "nil")")
                return true
            } else {
                errorMessage = response.errors?.first ?? "Login failed"
                print("❌ [Login] FAILED — \(errorMessage ?? "unknown")")
                return false
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
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
                    phoneNumber: phone
                )
            )

            if response.success, let token = response.token {
                APIClient.shared.setToken(token)
                currentUser = response.user
                saveUser(response.user)
                isAuthenticated = true
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

    func logout() {
        APIClient.shared.clearToken()
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "current_user")
    }

    private func saveUser(_ user: UserDTO?) {
        guard let user else { return }
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "current_user")
        }
    }
}
