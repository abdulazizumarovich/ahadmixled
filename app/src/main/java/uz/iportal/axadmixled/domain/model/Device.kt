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

    @field:SerializedName("code")
    val code: Int? = null,

    @field:SerializedName("data")
    val data: DeviceRegisterResponseData? = null,

    @field:SerializedName("status")
    val status: String? = null
)

data class DeviceRegisterResponseData(

    @field:SerializedName("volume")
    val volume: Int,

    @field:SerializedName("free_storage")
    val freeStorage: String,

    @field:SerializedName("brightness")
    val brightness: Int,

    @field:SerializedName("app_version")
    val appVersion: String,

    @field:SerializedName("mac_address")
    val macAddress: String,

    @field:SerializedName("total_storage")
    val totalStorage: String,

    @field:SerializedName("sn_number")
    val snNumber: String,

    @field:SerializedName("id")
    val id: Int,

    @field:SerializedName("ip_address")
    val ipAddress: String
)


data class DeviceStorageUpdate(
    val type: String = "device_storage",
    val snNumber: String,
    val storageTotal: Long,
    val storageFree: Long,
    val storageUsed: Long,
    val timestamp: Long = System.currentTimeMillis()
)
