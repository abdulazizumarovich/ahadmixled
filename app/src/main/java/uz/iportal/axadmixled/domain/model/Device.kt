package uz.iportal.axadmixled.domain.model

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

data class DeviceRegisterRequest(
    val snNumber: String,
    val name: String,
    val model: String,
    val osVersion: String,
    val screenResolution: String,
    val storageCapacity: Long
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
