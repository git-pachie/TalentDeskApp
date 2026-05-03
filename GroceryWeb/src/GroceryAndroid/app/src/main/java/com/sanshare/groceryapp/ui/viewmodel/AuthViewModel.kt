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
        // Restore session
        _state.update { it.copy(isAuthenticated = tokenManager.isAuthenticated) }

        // Listen for 401 events
        viewModelScope.launch {
            apiClient.unauthorizedEvent.collect {
                handleSessionExpired()
            }
        }

        // Restore cached user
        viewModelScope.launch {
            userPreferences.currentUserJson.collect { userJson ->
                if (userJson != null && tokenManager.isAuthenticated) {
                    try {
                        val user = json.decodeFromString<UserDto>(userJson)
                        _state.update { it.copy(currentUser = user) }
                    } catch (e: Exception) { /* ignore */ }
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
                    _state.update {
                        it.copy(isLoading = false, errorMessage = result.message)
                    }
                }
            }
        }
    }

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
                        refreshCurrentUser()
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
                            it.copy(isLoading = false, errorMessage = resp.error ?: "Verification failed")
                        }
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, errorMessage = result.message) }
                }
            }
        }
    }

    fun refreshCurrentUser() {
        viewModelScope.launch {
            if (!tokenManager.isAuthenticated) { handleSessionExpired(); return@launch }
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
    }

    fun logout() {
        tokenManager.clearToken()
        viewModelScope.launch { userPreferences.clearUser() }
        _state.update {
            AuthState(isAuthenticated = false)
        }
    }

    fun clearError() {
        _state.update { it.copy(errorMessage = null) }
    }

    private suspend fun saveUser(user: UserDto) {
        try {
            val userJson = json.encodeToString(user)
            userPreferences.saveUserJson(userJson)
        } catch (e: Exception) { /* ignore */ }
    }

    private suspend fun getOrCreateDeviceGuid(): String {
        var guid: String? = null
        userPreferences.deviceGuid.collect { guid = it }
        if (guid.isNullOrBlank()) {
            guid = UUID.randomUUID().toString()
            userPreferences.setDeviceGuid(guid!!)
        }
        return guid!!
    }
}
