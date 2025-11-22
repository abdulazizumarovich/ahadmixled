package uz.iportal.axadmixled.data.repository

import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import timber.log.Timber
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.data.remote.api.ScreenshotApi
import uz.iportal.axadmixled.domain.repository.ScreenshotRepository
import java.io.File
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton

@Singleton
class ScreenshotRepositoryImpl @Inject constructor(
    private val screenshotApiProvider: Provider<ScreenshotApi>,
    private val authPreferences: AuthPreferences
) : ScreenshotRepository {

    override suspend fun uploadScreenshot(mediaId: Int, screenshotFile: File): Result<Unit> {
        return try {
            val accessToken = authPreferences.getAccessToken()
            val snNumber = authPreferences.getDeviceSnNumber()

            if (accessToken.isNullOrEmpty() || snNumber.isNullOrEmpty()) {
                Timber.e("Missing authentication or device SN for screenshot upload")
                return Result.failure(Exception("Not authenticated or device not registered"))
            }

            if (!screenshotFile.exists()) {
                Timber.e("Screenshot file does not exist: ${screenshotFile.absolutePath}")
                return Result.failure(Exception("Screenshot file not found"))
            }

            Timber.d("Uploading screenshot for media: $mediaId")

            // Prepare multipart request
            val snNumberBody = snNumber.toRequestBody("text/plain".toMediaTypeOrNull())
            val mediaIdBody = mediaId.toString().toRequestBody("text/plain".toMediaTypeOrNull())
            val timestampBody = System.currentTimeMillis().toString()
                .toRequestBody("text/plain".toMediaTypeOrNull())

            val requestFile = screenshotFile.asRequestBody("image/jpeg".toMediaTypeOrNull())
            val screenshotPart = MultipartBody.Part.createFormData(
                "screenshot",
                screenshotFile.name,
                requestFile
            )

            // Upload screenshot
            screenshotApiProvider.get().uploadScreenshot(
                token = "Bearer $accessToken",
                snNumber = snNumberBody,
                mediaId = mediaIdBody,
                timestamp = timestampBody,
                screenshot = screenshotPart
            )

            Timber.d("Screenshot uploaded successfully for media: $mediaId")

            // Delete local screenshot file after successful upload
            try {
                if (screenshotFile.delete()) {
                    Timber.d("Local screenshot file deleted: ${screenshotFile.name}")
                }
            } catch (e: Exception) {
                Timber.w(e, "Failed to delete local screenshot file")
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Timber.e(e, "Failed to upload screenshot for media: $mediaId")
            Result.failure(e)
        }
    }
}
