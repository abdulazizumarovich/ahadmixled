package uz.iportal.axadmixled.data.remote.api

import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.http.*

interface ScreenshotApi {
    @Multipart
    @POST("api/v1/admin/cloud/screenshots/")
    suspend fun uploadScreenshot(
        @Header("Authorization") token: String,
        @Part("sn_number") snNumber: RequestBody,
        @Part("media_id") mediaId: RequestBody,
        @Part("timestamp") timestamp: RequestBody,
        @Part screenshot: MultipartBody.Part
    ): ResponseBody
}
