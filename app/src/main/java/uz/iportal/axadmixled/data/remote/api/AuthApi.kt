package uz.iportal.axadmixled.data.remote.api

import retrofit2.http.Body
import retrofit2.http.POST
import uz.iportal.axadmixled.domain.model.LoginRequest
import uz.iportal.axadmixled.domain.model.LoginResponse
import uz.iportal.axadmixled.domain.model.RefreshTokenRequest
import uz.iportal.axadmixled.domain.model.RefreshTokenResponse

interface AuthApi {
    @POST("api/v1/auth/token/")
    suspend fun login(@Body request: LoginRequest): LoginResponse

    @POST("api/v1/auth/token/refresh/")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): RefreshTokenResponse
}
