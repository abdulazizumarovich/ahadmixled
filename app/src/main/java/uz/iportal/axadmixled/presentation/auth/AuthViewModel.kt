package uz.iportal.axadmixled.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.domain.model.LoginRequest
import uz.iportal.axadmixled.domain.repository.AuthRepository
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val deviceRepository: DeviceRepository
) : ViewModel() {

    private val _loginState = MutableStateFlow<LoginState>(LoginState.Idle)
    val loginState: StateFlow<LoginState> = _loginState.asStateFlow()

    private val _navigationEvent = MutableSharedFlow<NavigationEvent>()
    val navigationEvent: SharedFlow<NavigationEvent> = _navigationEvent.asSharedFlow()

    fun login(username: String, password: String) {
        viewModelScope.launch {
            try {
                Timber.d("Attempting login for user: $username")
                _loginState.value = LoginState.Loading

                // Validate inputs
                if (username.isBlank() || password.isBlank()) {
                    Timber.w("Login failed: empty credentials")
                    _loginState.value = LoginState.Error("Username and password are required")
                    return@launch
                }

                // Perform login
                val request = LoginRequest(username = username, password = password)
                val result = authRepository.login(request)

                result.onSuccess { tokens ->
                    Timber.d("Login successful")
                    authRepository.saveTokens(tokens)

                    // Register device after successful login
                    try {
                        Timber.d("Registering device")
                        deviceRepository.registerDevice()
                    } catch (e: Exception) {
                        Timber.e(e, "Failed to register device, continuing anyway")
                    }

                    _loginState.value = LoginState.Success
                    _navigationEvent.emit(NavigationEvent.NavigateToPlayer)
                }.onFailure { error ->
                    Timber.e(error, "Login failed")
                    _loginState.value = LoginState.Error(
                        error.message ?: "Login failed. Please check your credentials."
                    )
                }
            } catch (e: Exception) {
                Timber.e(e, "Unexpected error during login")
                _loginState.value = LoginState.Error(
                    "An unexpected error occurred. Please try again."
                )
            }
        }
    }

    fun clearError() {
        if (_loginState.value is LoginState.Error) {
            _loginState.value = LoginState.Idle
        }
    }

    fun resetState() {
        _loginState.value = LoginState.Idle
    }
}

sealed class LoginState {
    object Idle : LoginState()
    object Loading : LoginState()
    object Success : LoginState()
    data class Error(val message: String) : LoginState()
}

sealed class NavigationEvent {
    object NavigateToPlayer : NavigationEvent()
}
