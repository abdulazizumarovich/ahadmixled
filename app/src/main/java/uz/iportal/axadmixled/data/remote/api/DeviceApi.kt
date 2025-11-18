package uz.iportal.axadmixled.data.remote.api

import retrofit2.http.*
import uz.iportal.axadmixled.domain.model.Device
import uz.iportal.axadmixled.domain.model.DeviceRegisterRequest
import uz.iportal.axadmixled.domain.model.DeviceRegisterResponse

interface DeviceApi {
    @POST("api/v1/admin/cloud/device/register/")
    suspend fun registerDevice(
        @Header("Authorization") token: String,
        @Body request: DeviceRegisterRequest
    ): DeviceRegisterResponse

    @GET("api/v1/admin/cloud/device/{sn_number}/")
    suspend fun getDeviceInfo(
        @Header("Authorization") token: String,
        @Path("sn_number") snNumber: String
    ): Device
}
