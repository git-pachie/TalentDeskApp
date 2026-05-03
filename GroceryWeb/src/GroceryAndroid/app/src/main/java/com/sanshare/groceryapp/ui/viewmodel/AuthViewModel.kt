package com.sanshare.groceryapp.ui.viewmodel

import android.os.Build
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.local.TokenManager
import com.sanshare.groceryapp.data.local.UserPreferences
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID
import javax.inject.Inject

data class AuthState(
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = false,
    val currentUser: UserDto? = null,
    val errorMessage: String? = null,
    val requiresEmailVerification: Boolean = false,
    val pendingVerificationEmail: String = "",
    // Profile verification sheet state
    val showEmailVerifySheet: Boolean = false,
    val showPhoneVerifySheet: Boolean = false,
    val isSendingEmailCode: Boolean = false,
    val isSendingPhoneCode: Boolean = false,
    val successMessage: String? = null,   // dismissable banner shown after verify success
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val apiClient: ApiClient,
    private val tokenManager: TokenManager,
    private val userPreferences: UserPreferences,
) : ViewModel() {

    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state.asStateFlow()

    private val json = Json { ignoreUnknownKeys = true }

    init {
        _state.update { it.copy(isAuthenticated = tokenManager.isAuthenticated) }

        viewModelScope.launch {
            apiClient.unauthorizedEvent.collect { handleSessionExpired() }
        }

        viewModelScope.launch {
            userPreferences.currentUserJson.collect { userJson ->
                if (userJson != null && tokenManager.isAuthenticated) {
                    try {
                        val user = json.decodeFromString<UserDto>(userJson)
                        _state.update { it.copy(currentUser = user) }
                    } catch (_: Exception) { }
                }
            }
        }
    }

    private fun handleSessionExpired() {
        if (!_state.value.isAuthenticated) return
        tokenManager.clearToken()
        viewModelScope.launch { userPreferences.clearUser() }
        _state.update {
            it.copy(
                isAuthenticated = false,
                currentUser = null,
                errorMessage = "Your session has expired. Please log in again.",
            )
        }
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            val deviceGuid = getOrCreateDeviceGuid()
            val result = apiClient.post<LoginRequest, AuthResponse>(
                ApiConfig.AUTH_LOGIN,
                LoginRequest(
                    email = email,
                    password = password,
                    deviceGuid = deviceGuid,
                    osVersion = "Android ${Build.VERSION.RELEASE}",
                    hardwareVersion = "${Build.MANUFACTURER} ${Build.MODEL}",
                )
            )
            when (result) {
                is ApiResult.Success -> {
                    val resp = result.data
                    when {
                        resp.success && resp.token != null -> {
                            tokenManager.setToken(resp.token)
                            resp.user?.let { saveUser(it) }
                            _state.update {
                                it.copy(
                                    isAuthenticated = true,
                                    currentUser = resp.user,
                                    isLoading = false,
                                    requiresEmailVerification = false,
                                )
                            }
                        }
                        resp.requiresEmailVerification == true -> {
                            _state.update {
                                it.copy(
                                    isLoading = false,
                                    requiresEmailVerification = true,
                                    pendingVerificationEmail = email,
                                )
                            }
                        }
                        else -> {
                            _state.update {
                                it.copy(
                                    isLoading = false,
                                    errorMessage = resp.errors?.firstOrNull() ?: "Login failed",
                                )
                            }
                        }
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, errorMessage = result.message) }
                }
            }
        }
    }

    // ── Register ──────────────────────────────────────────────────────────────

    fun register(firstName: String, lastName: String, email: String, password: String, phone: String?) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            val deviceGuid = getOrCreateDeviceGuid()
            val result = apiClient.post<RegisterRequest, AuthResponse>(
                ApiConfig.AUTH_REGISTER,
                RegisterRequest(
                    firstName = firstName,
                    lastName = lastName,
                    email = email,
                    password = password,
                    phoneNumber = phone?.ifBlank { null },
                    deviceGuid = deviceGuid,
                    osVersion = "Android ${Build.VERSION.RELEASE}",
                    hardwareVersion = "${Build.MANUFACTURER} ${Build.MODEL}",
                )
            )
            when (result) {
                is ApiResult.Success -> {
                    val resp = result.data
                    when {
                        resp.success && resp.token != null -> {
                            tokenManager.setToken(resp.token)
                            resp.user?.let { saveUser(it) }
                            _state.update {
                                it.copy(isAuthenticated = true, currentUser = resp.user, isLoading = false)
                            }
                        }
                        resp.requiresEmailVerification == true -> {
                            _state.update {
                                it.copy(
                                    isLoading = false,
                                    requiresEmailVerification = true,
                                    pendingVerificationEmail = email,
                                )
                            }
                        }
                        else -> {
                            _state.update {
                                it.copy(
                                    isLoading = false,
                                    errorMessage = resp.errors?.firstOrNull() ?: "Registration failed",
                                )
                            }
                        }
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, errorMessage = result.message) }
                }
            }
        }
    }

    // ── Email Verification (login flow — no token yet) ────────────────────────

    fun verifyEmail(code: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            val result = apiClient.post<VerifyEmailRequest, VerifyEmailResponse>(
                ApiConfig.AUTH_VERIFY_EMAIL,
                VerifyEmailRequest(email = _state.value.pendingVerificationEmail, code = code)
            )
            when (result) {
                is ApiResult.Success -> {
                    val resp = result.data
                    if (resp.success && resp.token != null) {
                        tokenManager.setToken(resp.token)
                        fetchAndSaveCurrentUser()
                        _state.update {
                            it.copy(
                                isAuthenticated = true,
                                requiresEmailVerification = false,
                                pendingVerificationEmail = "",
                                isLoading = false,
                            )
                        }
                    } else {
                        _state.update {
                            it.copy(isLoading = false, errorMessage = resp.error ?: "Incorrect code. Please try again.")
                        }
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, errorMessage = result.message) }
                }
            }
        }
    }

    fun resendEmailVerificationCode() {
        if (_state.value.pendingVerificationEmail.isBlank()) return
        viewModelScope.launch {
            _state.update { it.copy(isSendingEmailCode = true, errorMessage = null) }
            apiClient.postEmpty(ApiConfig.AUTH_SEND_EMAIL_CODE)
            _state.update { it.copy(isSendingEmailCode = false) }
        }
    }

    // ── Profile Verification (authenticated — has token) ──────────────────────

    fun startEmailVerification() {
        viewModelScope.launch {
            _state.update { it.copy(isSendingEmailCode = true, errorMessage = null) }
            val (ok, err) = apiClient.postEmpty(ApiConfig.AUTH_SEND_EMAIL_CODE)
            if (ok) {
                _state.update { it.copy(isSendingEmailCode = false, showEmailVerifySheet = true, successMessage = null) }
            } else {
                _state.update { it.copy(isSendingEmailCode = false, errorMessage = err ?: "Failed to send code. Please try again.") }
            }
        }
    }

    fun startPhoneVerification() {
        viewModelScope.launch {
            _state.update { it.copy(isSendingPhoneCode = true, errorMessage = null) }
            val (ok, err) = apiClient.postEmpty(ApiConfig.AUTH_SEND_PHONE_CODE)
            if (ok) {
                _state.update { it.copy(isSendingPhoneCode = false, showPhoneVerifySheet = true, successMessage = null) }
            } else {
                _state.update { it.copy(isSendingPhoneCode = false, errorMessage = err ?: "Failed to send SMS code. Please try again.") }
            }
        }
    }

    fun verifyEmailFromProfile(code: String) {
        val email = _state.value.currentUser?.email ?: return
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            val result = apiClient.post<VerifyEmailRequest, VerifyEmailResponse>(
                ApiConfig.AUTH_VERIFY_EMAIL,
                VerifyEmailRequest(email = email, code = code)
            )
            when (result) {
                is ApiResult.Success -> {
                    if (result.data.success) {
                        fetchAndSaveCurrentUser()
                        _state.update {
                            it.copy(
                                isLoading = false,
                                showEmailVerifySheet = false,
                                successMessage = "✅ Email verified successfully!",
                            )
                        }
                    } else {
                        _state.update {
                            it.copy(isLoading = false, errorMessage = result.data.error ?: "Incorrect code. Please try again.")
                        }
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, errorMessage = result.message) }
                }
            }
        }
    }

    fun verifyPhoneFromProfile(code: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            val result = apiClient.post<VerifyPhoneRequest, VerifyPhoneResponse>(
                ApiConfig.AUTH_VERIFY_PHONE,
                VerifyPhoneRequest(code = code)
            )
            when (result) {
                is ApiResult.Success -> {
                    if (result.data.success) {
                        fetchAndSaveCurrentUser()
                        _state.update {
                            it.copy(
                                isLoading = false,
                                showPhoneVerifySheet = false,
                                successMessage = "✅ Mobile number verified successfully!",
                            )
                        }
                    } else {
                        _state.update {
                            it.copy(isLoading = false, errorMessage = result.data.error ?: "Incorrect code. Please try again.")
                        }
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, errorMessage = result.message) }
                }
            }
        }
    }

    fun resendEmailCodeFromProfile() {
        viewModelScope.launch {
            _state.update { it.copy(isSendingEmailCode = true, errorMessage = null) }
            apiClient.postEmpty(ApiConfig.AUTH_SEND_EMAIL_CODE)
            _state.update { it.copy(isSendingEmailCode = false) }
        }
    }

    fun resendPhoneCodeFromProfile() {
        viewModelScope.launch {
            _state.update { it.copy(isSendingPhoneCode = true, errorMessage = null) }
            apiClient.postEmpty(ApiConfig.AUTH_SEND_PHONE_CODE)
            _state.update { it.copy(isSendingPhoneCode = false) }
        }
    }

    fun dismissEmailVerifySheet() {
        _state.update { it.copy(showEmailVerifySheet = false, errorMessage = null) }
    }

    fun dismissPhoneVerifySheet() {
        _state.update { it.copy(showPhoneVerifySheet = false, errorMessage = null) }
    }

    fun dismissSuccessMessage() {
        _state.update { it.copy(successMessage = null) }
    }

    // ── Shared ────────────────────────────────────────────────────────────────

    fun refreshCurrentUser() {
        viewModelScope.launch {
            if (!tokenManager.isAuthenticated) { handleSessionExpired(); return@launch }
            fetchAndSaveCurrentUser()
        }
    }

    fun logout() {
        tokenManager.clearToken()
        viewModelScope.launch { userPreferences.clearUser() }
        _state.update { AuthState(isAuthenticated = false) }
    }

    fun clearError() {
        _state.update { it.copy(errorMessage = null) }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private suspend fun fetchAndSaveCurrentUser() {
        val result = apiClient.get<UserDto>(ApiConfig.AUTH_ME)
        if (result is ApiResult.Success) {
            val user = result.data
            saveUser(user)
            _state.update {
                it.copy(
                    currentUser = user,
                    isAuthenticated = true,
                    requiresEmailVerification = user.isEmailVerified == false,
                    pendingVerificationEmail = if (user.isEmailVerified == false) user.email else "",
                )
            }
        }
    }

    private suspend fun saveUser(user: UserDto) {
        try {
            userPreferences.saveUserJson(json.encodeToString(user))
        } catch (_: Exception) { }
    }

    private suspend fun getOrCreateDeviceGuid(): String {
        val existing = userPreferences.deviceGuid.first()
        if (!existing.isNullOrBlank()) return existing
        val newGuid = UUID.randomUUID().toString()
        userPreferences.setDeviceGuid(newGuid)
        return newGuid
    }
}
