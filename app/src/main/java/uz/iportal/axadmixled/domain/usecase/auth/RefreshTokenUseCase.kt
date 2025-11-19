package uz.iportal.axadmixled.domain.usecase.auth

import uz.iportal.axadmixled.domain.model.AuthTokens
import uz.iportal.axadmixled.domain.repository.AuthRepository
import javax.inject.Inject

class RefreshTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(): Result<AuthTokens> {
        return authRepository.refreshToken()
    }
}
