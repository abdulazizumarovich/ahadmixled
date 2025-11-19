package uz.iportal.axadmixled.data.repository

import android.os.Build
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
import uz.iportal.axadmixled.util.DeviceInfoProvider
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DeviceRepositoryImpl @Inject constructor(
    private val deviceApi: DeviceApi,
    private val deviceDao: DeviceDao,
    private val playlistDao: PlaylistDao,
    private val authPreferences: AuthPreferences,
    private val deviceInfoProvider: DeviceInfoProvider
) : DeviceRepository {

    override suspend fun registerDevice(): Result<DeviceRegisterResponse> {
        return try {
            val accessToken = authPreferences.getAccessToken()
            if (accessToken.isNullOrEmpty()) {
                Timber.e("No access token available for device registration")
                return Result.failure(Exception("Not authenticated"))
            }

            val snNumber = getOrGenerateSnNumber()
            val totalStorage = getTotalStorage()
            val freeStorage = getFreeStorage()

            Timber.d("Registering device with SN: $snNumber")
            Timber.d("Device info - Brand: ${Build.BRAND}, Manufacturer: ${Build.MANUFACTURER}, Model: ${Build.MODEL}")

            val request = DeviceRegisterRequest(
                snNumber = snNumber,
                brand = Build.BRAND,
                model = Build.MODEL,
                manufacturer = Build.MANUFACTURER,
                osVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
                screenResolution = getScreenResolution(),
                totalStorage = formatStorage(totalStorage),
                freeStorage = formatStorage(freeStorage),
                macAddress = getMacAddress(),
                appVersion = getAppVersion(),
                ipAddress = getIpAddress(),
                brightness = 50,
                volume = 50
            )

            Timber.d("Sending device registration request: $request")

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
                storageTotal = totalStorage,
                storageFree = freeStorage,
                storageUsed = totalStorage - freeStorage,
                isActive = response.isActive,
                createdAt = response.createdAt,
                registeredAt = System.currentTimeMillis()
            )
            deviceDao.insertDevice(deviceEntity)

            // Save SN number in preferences
            authPreferences.saveDeviceSnNumber(snNumber)

            Timber.d("Device registered successfully: ${response.name} (ID: ${response.id})")
            Result.success(response)
        } catch (e: Exception) {
            Timber.e(e, "Device registration failed: ${e.message}")
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

        // Check if existing SN is valid (not the old "LED-" prefixed format or literal "LED-ANDROID_ID")
        val isValidSn = !existingSn.isNullOrEmpty() &&
                        !existingSn.startsWith("LED-") &&
                        existingSn != "LED-ANDROID_ID" &&
                        existingSn != "ANDROID_ID"

        if (isValidSn) {
            Timber.d("Using existing valid SN: $existingSn")
            return existingSn
        }

        if (!existingSn.isNullOrEmpty()) {
            Timber.w("Invalid SN detected: '$existingSn', regenerating...")
        }

        // Generate unique SN using DeviceInfoProvider (matches Flutter implementation)
        val snNumber = deviceInfoProvider.generateSerialNumber()
        Timber.d("Generated new device SN: $snNumber")

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

    private fun formatStorage(bytes: Long): String {
        return try {
            val gb = bytes / (1024.0 * 1024.0 * 1024.0)
            String.format("%.2f GB", gb)
        } catch (e: Exception) {
            "0 GB"
        }
    }

    private fun getMacAddress(): String? {
        return try {
            val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.name.equals("wlan0", ignoreCase = true)) {
                    val mac = networkInterface.hardwareAddress
                    if (mac != null) {
                        val macAddress = StringBuilder()
                        for (byte in mac) {
                            macAddress.append(String.format("%02X:", byte))
                        }
                        if (macAddress.isNotEmpty()) {
                            macAddress.deleteCharAt(macAddress.length - 1)
                        }
                        return macAddress.toString()
                    }
                }
            }
            null
        } catch (e: Exception) {
            Timber.e(e, "Failed to get MAC address")
            null
        }
    }

    private fun getAppVersion(): String {
        return try {
            uz.iportal.axadmixled.BuildConfig.VERSION_NAME
        } catch (e: Exception) {
            "1.0"
        }
    }

    private fun getIpAddress(): String? {
        return try {
            val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is java.net.Inet4Address) {
                        return address.hostAddress
                    }
                }
            }
            null
        } catch (e: Exception) {
            Timber.e(e, "Failed to get IP address")
            null
        }
    }
}
