package uz.iportal.axadmixled.domain.model

data class AuthTokens(
    val access: String,
    val refresh: String,
    val expiresAt: Long = System.currentTimeMillis() + (24 * 60 * 60 * 1000)
)

data class LoginRequest(
    val username: String,
    val password: String
)

data class LoginResponse(
    val access: String,
    val refresh: String
)

data class RefreshTokenRequest(
    val refresh: String
)

data class RefreshTokenResponse(
    val access: String,
    val refresh: String
)
