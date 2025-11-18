package uz.iportal.axadmixled.data.repository

import android.os.Build
import android.provider.Settings
import timber.log.Timber
import uz.iportal.axadmixled.data.local.database.dao.DeviceDao
import uz.iportal.axadmixled.data.local.database.dao.PlaylistDao
import uz.iportal.axadmixled.data.local.database.entities.DeviceEntity
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.data.remote.api.DeviceApi
import uz.iportal.axadmixled.domain.model.Device
import uz.iportal.axadmixled.domain.model.DeviceRegisterRequest
import uz.iportal.axadmixled.domain.model.DeviceRegisterResponse
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DeviceRepositoryImpl @Inject constructor(
    private val deviceApi: DeviceApi,
    private val deviceDao: DeviceDao,
    private val playlistDao: PlaylistDao,
    private val authPreferences: AuthPreferences
) : DeviceRepository {

    override suspend fun registerDevice(): Result<DeviceRegisterResponse> {
        return try {
            val accessToken = authPreferences.getAccessToken()
            if (accessToken.isNullOrEmpty()) {
                Timber.e("No access token available for device registration")
                return Result.failure(Exception("Not authenticated"))
            }

            val snNumber = getOrGenerateSnNumber()
            Timber.d("Registering device with SN: $snNumber")

            val request = DeviceRegisterRequest(
                snNumber = snNumber,
                name = "${Build.MANUFACTURER} ${Build.MODEL}",
                model = Build.MODEL,
                osVersion = "Android ${Build.VERSION.RELEASE}",
                screenResolution = getScreenResolution(),
                storageCapacity = getTotalStorage()
            )

            val response = deviceApi.registerDevice(
                token = "Bearer $accessToken",
                request = request
            )

            // Save device info locally
            val deviceEntity = DeviceEntity(
                id = response.id,
                snNumber = response.snNumber,
                name = response.name,
                model = Build.MODEL,
                androidVersion = "Android ${Build.VERSION.RELEASE}",
                screenResolution = getScreenResolution(),
                storageTotal = getTotalStorage(),
                storageFree = getFreeStorage(),
                storageUsed = getTotalStorage() - getFreeStorage(),
                isActive = response.isActive,
                createdAt = response.createdAt,
                registeredAt = System.currentTimeMillis()
            )
            deviceDao.insertDevice(deviceEntity)

            // Save SN number in preferences
            authPreferences.saveDeviceSnNumber(snNumber)

            Timber.d("Device registered successfully: ${response.name}")
            Result.success(response)
        } catch (e: Exception) {
            Timber.e(e, "Device registration failed")
            Result.failure(e)
        }
    }

    override suspend fun getDeviceInfo(): Result<Device> {
        return try {
            val accessToken = authPreferences.getAccessToken()
            val snNumber = authPreferences.getDeviceSnNumber()

            if (accessToken.isNullOrEmpty() || snNumber.isNullOrEmpty()) {
                Timber.e("Missing authentication or device SN")
                return Result.failure(Exception("Not authenticated or device not registered"))
            }

            Timber.d("Fetching device info for SN: $snNumber")
            val device = deviceApi.getDeviceInfo(
                token = "Bearer $accessToken",
                snNumber = snNumber
            )

            // Update local database
            val deviceEntity = DeviceEntity(
                id = device.id,
                snNumber = device.snNumber,
                name = device.name,
                model = device.model,
                androidVersion = device.androidVersion,
                screenResolution = device.screenResolution,
                storageTotal = device.storageTotal,
                storageFree = device.storageFree,
                storageUsed = device.storageUsed,
                isActive = device.isActive,
                createdAt = device.createdAt,
                registeredAt = System.currentTimeMillis()
            )
            deviceDao.insertDevice(deviceEntity)

            Timber.d("Device info fetched successfully")
            Result.success(device)
        } catch (e: Exception) {
            Timber.e(e, "Failed to fetch device info")
            Result.failure(e)
        }
    }

    override suspend fun isDeviceRegistered(): Boolean {
        val snNumber = authPreferences.getDeviceSnNumber()
        val device = deviceDao.getDevice()
        return !snNumber.isNullOrEmpty() && device != null
    }

    override suspend fun getDeviceSnNumber(): String? {
        return authPreferences.getDeviceSnNumber()
    }

    override suspend fun updateStorageInfo(total: Long, free: Long, used: Long) {
        try {
            deviceDao.updateStorage(total = total, free = free, used = used)
            Timber.d("Storage info updated: total=$total, free=$free, used=$used")
        } catch (e: Exception) {
            Timber.e(e, "Failed to update storage info")
        }
    }

    override suspend fun getReadyPlaylistIds(): List<Int> {
        return try {
            playlistDao.getReadyPlaylistIds()
        } catch (e: Exception) {
            Timber.e(e, "Failed to get ready playlist IDs")
            emptyList()
        }
    }

    private fun getOrGenerateSnNumber(): String {
        val existingSn = authPreferences.getDeviceSnNumber()
        if (!existingSn.isNullOrEmpty()) {
            return existingSn
        }

        // Generate unique SN based on Android ID or UUID
        val androidId = try {
            Settings.Secure.ANDROID_ID
        } catch (e: Exception) {
            null
        }

        val snNumber = if (!androidId.isNullOrEmpty() && androidId != "9774d56d682e549c") {
            "LED-${androidId.uppercase()}"
        } else {
            "LED-${UUID.randomUUID().toString().replace("-", "").take(16).uppercase()}"
        }

        authPreferences.saveDeviceSnNumber(snNumber)
        return snNumber
    }

    private fun getScreenResolution(): String {
        return try {
            val displayMetrics = android.content.res.Resources.getSystem().displayMetrics
            "${displayMetrics.widthPixels}x${displayMetrics.heightPixels}"
        } catch (e: Exception) {
            "1920x1080"
        }
    }

    private fun getTotalStorage(): Long {
        return try {
            val stat = android.os.StatFs(android.os.Environment.getDataDirectory().path)
            stat.totalBytes
        } catch (e: Exception) {
            Timber.e(e, "Failed to get total storage")
            0L
        }
    }

    private fun getFreeStorage(): Long {
        return try {
            val stat = android.os.StatFs(android.os.Environment.getDataDirectory().path)
            stat.availableBytes
        } catch (e: Exception) {
            Timber.e(e, "Failed to get free storage")
            0L
        }
    }
}
