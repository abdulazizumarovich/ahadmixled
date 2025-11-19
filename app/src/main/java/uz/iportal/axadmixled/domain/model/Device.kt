package uz.iportal.axadmixled.domain.model

import com.google.gson.annotations.SerializedName

data class Device(
    val id: Int,
    val snNumber: String,
    val name: String,
    val model: String,
    val androidVersion: String,
    val screenResolution: String,
    val storageTotal: Long,
    val storageFree: Long,
    val storageUsed: Long,
    val lastOnline: String,
    val isActive: Boolean,
    val createdAt: String,
    val updatedAt: String
)

/**
 * Device Registration Request
 * Matches Flutter DeviceModel implementation for backend compatibility
 */
data class DeviceRegisterRequest(
    @SerializedName("sn_number")
    val snNumber: String,

    @SerializedName("brand")
    val brand: String,

    @SerializedName("model")
    val model: String,

    @SerializedName("manufacturer")
    val manufacturer: String,

    @SerializedName("os_version")
    val osVersion: String,

    @SerializedName("screen_resolution")
    val screenResolution: String,

    @SerializedName("total_storage")
    val totalStorage: String,

    @SerializedName("free_storage")
    val freeStorage: String,

    @SerializedName("mac_address")
    val macAddress: String? = null,

    @SerializedName("app_version")
    val appVersion: String,

    @SerializedName("ip_address")
    val ipAddress: String? = null,

    @SerializedName("brightness")
    val brightness: Int = 50,

    @SerializedName("volume")
    val volume: Int = 50
)

data class DeviceRegisterResponse(
    val id: Int,
    val snNumber: String,
    val name: String,
    val isActive: Boolean,
    val createdAt: String
)

data class DeviceStorageUpdate(
    val type: String = "device_storage",
    val snNumber: String,
    val storageTotal: Long,
    val storageFree: Long,
    val storageUsed: Long,
    val timestamp: Long = System.currentTimeMillis()
)
