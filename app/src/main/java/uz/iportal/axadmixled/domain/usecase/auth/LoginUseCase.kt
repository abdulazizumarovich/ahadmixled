package uz.iportal.axadmixled.domain.usecase.auth

import uz.iportal.axadmixled.domain.model.AuthTokens
import uz.iportal.axadmixled.domain.model.LoginRequest
import uz.iportal.axadmixled.domain.repository.AuthRepository
import javax.inject.Inject

class LoginUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(username: String, password: String): Result<AuthTokens> {
        if (username.isBlank()) {
            return Result.failure(Exception("Username cannot be empty"))
        }
        if (password.isBlank()) {
            return Result.failure(Exception("Password cannot be empty"))
        }

        val request = LoginRequest(username, password)

        return authRepository.login(request)
    }
}
