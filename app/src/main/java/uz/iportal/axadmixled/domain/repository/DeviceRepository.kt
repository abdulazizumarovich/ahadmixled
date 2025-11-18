package uz.iportal.axadmixled.domain.repository

import uz.iportal.axadmixled.domain.model.Device
import uz.iportal.axadmixled.domain.model.DeviceRegisterRequest
import uz.iportal.axadmixled.domain.model.DeviceRegisterResponse

interface DeviceRepository {
    suspend fun registerDevice(): Result<DeviceRegisterResponse>
    suspend fun getDeviceInfo(): Result<Device>
    suspend fun isDeviceRegistered(): Boolean
    suspend fun getDeviceSnNumber(): String?
    suspend fun updateStorageInfo(total: Long, free: Long, used: Long)
    suspend fun getReadyPlaylistIds(): List<Int>
}
