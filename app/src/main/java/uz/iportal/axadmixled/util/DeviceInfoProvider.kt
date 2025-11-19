package uz.iportal.axadmixled.util

import android.content.Context
import android.os.Build
import android.provider.Settings
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Provides device information for registration and identification
 */
@Singleton
class DeviceInfoProvider @Inject constructor(
    @ApplicationContext private val context: Context
) {
    /**
     * Generate unique serial number for the device
     * Uses Android ID (matching Flutter implementation - no prefix)
     */
    fun generateSerialNumber(): String {
        return try {
            val androidId = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            )
            if (androidId.isNullOrBlank() || androidId == "9774d56d682e549c") {
                // Fallback to UUID if Android ID is not available or is the emulator ID
                UUID.randomUUID().toString().replace("-", "").take(16)
            } else {
                // Plain ANDROID_ID, matching Flutter's androidInfo.id
                androidId
            }
        } catch (e: Exception) {
            // If all else fails, generate random UUID
            UUID.randomUUID().toString().replace("-", "").take(16)
        }
    }

    /**
     * Get device name (manufacturer + model)
     */
    fun getDeviceName(): String {
        return "${Build.MANUFACTURER} ${Build.MODEL}".trim()
    }

    /**
     * Get device model
     */
    fun getDeviceModel(): String {
        return Build.MODEL
    }

    /**
     * Get Android OS version
     */
    fun getOsVersion(): String {
        return "Android ${Build.VERSION.RELEASE}"
    }

    /**
     * Get screen resolution
     */
    fun getScreenResolution(): String {
        val displayMetrics = context.resources.displayMetrics
        return "${displayMetrics.widthPixels}x${displayMetrics.heightPixels}"
    }

    /**
     * Get total storage capacity in bytes
     */
    fun getStorageCapacity(): Long {
        val dataDir = context.getExternalFilesDir(null) ?: context.filesDir
        val stat = android.os.StatFs(dataDir.path)
        return stat.totalBytes
    }

    /**
     * Get free storage space in bytes
     */
    fun getFreeStorage(): Long {
        val dataDir = context.getExternalFilesDir(null) ?: context.filesDir
        val stat = android.os.StatFs(dataDir.path)
        return stat.availableBytes
    }

    /**
     * Get used storage space in bytes
     */
    fun getUsedStorage(): Long {
        return getStorageCapacity() - getFreeStorage()
    }

    /**
     * Get all device information as a map
     */
    fun getAllDeviceInfo(): Map<String, String> {
        return mapOf(
            "serial_number" to generateSerialNumber(),
            "device_name" to getDeviceName(),
            "device_model" to getDeviceModel(),
            "os_version" to getOsVersion(),
            "screen_resolution" to getScreenResolution(),
            "storage_capacity" to getStorageCapacity().toString(),
            "free_storage" to getFreeStorage().toString(),
            "used_storage" to getUsedStorage().toString(),
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "hardware" to Build.HARDWARE,
            "sdk_version" to Build.VERSION.SDK_INT.toString()
        )
    }
}
