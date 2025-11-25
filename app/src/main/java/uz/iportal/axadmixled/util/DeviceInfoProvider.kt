package uz.iportal.axadmixled.util

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.provider.Settings
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.UUID
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
     * Get or generate unique serial number for the device
     * Uses Serial NO or Android ID and falls back to random generated if not available
     */
    @Suppress("DEPRECATION")
    @SuppressLint("HardwareIds")
    fun generateSerialNumber(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O && Build.SERIAL != Build.UNKNOWN) {
            return Build.SERIAL
        }

        return try {
            val androidId = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            ) ?: throw IllegalStateException("Android ID not available")

            if (androidId == "9774d56d682e549c") {
                throw IllegalStateException("Android ID is a fake value")
            }
            androidId
        } catch (_: Exception) {
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
}
