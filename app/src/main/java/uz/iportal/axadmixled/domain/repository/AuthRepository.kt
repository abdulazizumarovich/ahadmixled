package uz.iportal.axadmixled.domain.repository

import uz.iportal.axadmixled.domain.model.AuthTokens
import uz.iportal.axadmixled.domain.model.LoginRequest

interface AuthRepository {
    suspend fun login(request: LoginRequest): Result<AuthTokens>
    suspend fun refreshToken(): Result<AuthTokens>
    suspend fun refreshTokenIfNeeded(): Result<AuthTokens>
    suspend fun getAccessToken(): String?
    suspend fun getRefreshToken(): String?
    suspend fun isAuthenticated(): Boolean
    suspend fun saveTokens(tokens: AuthTokens)
    suspend fun clearTokens()
}
