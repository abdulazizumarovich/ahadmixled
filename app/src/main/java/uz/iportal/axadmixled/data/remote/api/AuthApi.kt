package uz.iportal.axadmixled.data.remote.api

import retrofit2.http.Body
import retrofit2.http.POST
import uz.iportal.axadmixled.core.constants.ApiConstants
import uz.iportal.axadmixled.domain.model.LoginRequest
import uz.iportal.axadmixled.domain.model.LoginResponse
import uz.iportal.axadmixled.domain.model.RefreshTokenRequest
import uz.iportal.axadmixled.domain.model.RefreshTokenResponse

/**
 * Authentication API endpoints
 * Base URL: https://admin-led.ohayo.uz/api/v1
 */
interface AuthApi {
    @POST(ApiConstants.LOGIN)
    suspend fun login(@Body request: LoginRequest): LoginResponse

    @POST(ApiConstants.REFRESH_TOKEN)
    suspend fun refreshToken(@Body request: RefreshTokenRequest): RefreshTokenResponse
}
