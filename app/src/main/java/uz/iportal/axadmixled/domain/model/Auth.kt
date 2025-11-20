package uz.iportal.axadmixled.domain.model

import com.google.gson.annotations.SerializedName

data class AuthTokens(
    val access: String,
    val refresh: String,
    val expiresAt: Long = System.currentTimeMillis() + (24 * 60 * 60 * 1000)
)

data class LoginRequest(
    val username: String = "",
    val password: String = ""
)

data class LoginResponse(
    @field:SerializedName("access")
    val access: String? = null,

    @field:SerializedName("role")
    val role: String? = null,

    @field:SerializedName("refresh")
    val refresh: String? = null,

    @field:SerializedName("expire_in")
    val expireIn: String? = null,

    @field:SerializedName("refresh_expire")
    val refreshExpire: String? = null
)

data class RefreshTokenRequest(
    val refresh: String
)

data class RefreshTokenResponse(
    val access: String,
    val refresh: String
)
