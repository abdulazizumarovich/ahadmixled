package uz.iportal.axadmixled.data.remote.api

import retrofit2.http.*
import uz.iportal.axadmixled.core.constants.ApiConstants
import uz.iportal.axadmixled.domain.model.Device
import uz.iportal.axadmixled.domain.model.DeviceRegisterRequest
import uz.iportal.axadmixled.domain.model.DeviceRegisterResponse

interface DeviceApi {
    @POST(ApiConstants.DEVICE_REGISTER)
    suspend fun registerDevice(
        @Header("Authorization") token: String,
        @Body request: DeviceRegisterRequest
    ): DeviceRegisterResponse

    @GET(ApiConstants.DEVICE_INFO)
    suspend fun getDeviceInfo(
        @Header("Authorization") token: String,
        @Path("sn_number") snNumber: String
    ): Device
}
