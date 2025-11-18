package uz.iportal.axadmixled.data.repository

import timber.log.Timber
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.data.remote.api.AuthApi
import uz.iportal.axadmixled.domain.model.AuthTokens
import uz.iportal.axadmixled.domain.model.LoginRequest
import uz.iportal.axadmixled.domain.model.RefreshTokenRequest
import uz.iportal.axadmixled.domain.repository.AuthRepository
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val authApi: AuthApi,
    private val authPreferences: AuthPreferences
) : AuthRepository {

    override suspend fun login(request: LoginRequest): Result<AuthTokens> {
        return try {
            Timber.d("Attempting login for user: ${request.username}")
            val response = authApi.login(request)

            val tokens = AuthTokens(
                access = response.access,
                refresh = response.refresh,
                expiresAt = System.currentTimeMillis() + (24 * 60 * 60 * 1000) // 24 hours
            )

            saveTokens(tokens)
            Timber.d("Login successful")
            Result.success(tokens)
        } catch (e: Exception) {
            Timber.e(e, "Login failed")
            Result.failure(e)
        }
    }

    override suspend fun refreshToken(): Result<AuthTokens> {
        return try {
            val refreshToken = getRefreshToken()
            if (refreshToken.isNullOrEmpty()) {
                Timber.e("No refresh token available")
                return Result.failure(Exception("No refresh token available"))
            }

            Timber.d("Refreshing access token")
            val request = RefreshTokenRequest(refresh = refreshToken)
            val response = authApi.refreshToken(request)

            val tokens = AuthTokens(
                access = response.access,
                refresh = response.refresh,
                expiresAt = System.currentTimeMillis() + (24 * 60 * 60 * 1000) // 24 hours
            )

            saveTokens(tokens)
            Timber.d("Token refresh successful")
            Result.success(tokens)
        } catch (e: Exception) {
            Timber.e(e, "Token refresh failed")
            Result.failure(e)
        }
    }

    override suspend fun refreshTokenIfNeeded(): Result<AuthTokens> {
        return try {
            // Check if token is expired or will expire within 1 hour
            val expiresAt = authPreferences.getTokenExpiresAt()
            val oneHourFromNow = System.currentTimeMillis() + (60 * 60 * 1000)

            if (expiresAt <= oneHourFromNow) {
                Timber.d("Token expired or expiring soon, refreshing...")
                refreshToken()
            } else {
                val accessToken = getAccessToken()
                val refreshToken = getRefreshToken()

                if (accessToken.isNullOrEmpty() || refreshToken.isNullOrEmpty()) {
                    Result.failure(Exception("No tokens available"))
                } else {
                    val tokens = AuthTokens(
                        access = accessToken,
                        refresh = refreshToken,
                        expiresAt = expiresAt
                    )
                    Result.success(tokens)
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to check/refresh token")
            Result.failure(e)
        }
    }

    override suspend fun getAccessToken(): String? {
        return authPreferences.getAccessToken()
    }

    override suspend fun getRefreshToken(): String? {
        return authPreferences.getRefreshToken()
    }

    override suspend fun isAuthenticated(): Boolean {
        val accessToken = authPreferences.getAccessToken()
        val refreshToken = authPreferences.getRefreshToken()
        return !accessToken.isNullOrEmpty() && !refreshToken.isNullOrEmpty()
    }

    override suspend fun saveTokens(tokens: AuthTokens) {
        authPreferences.saveTokens(tokens)
        Timber.d("Tokens saved successfully")
    }

    override suspend fun clearTokens() {
        authPreferences.clearTokens()
        Timber.d("Tokens cleared")
    }
}
