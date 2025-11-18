package uz.iportal.axadmixled.data.local.database.dao

import androidx.room.*
import uz.iportal.axadmixled.data.local.database.entities.DeviceEntity

@Dao
interface DeviceDao {
    @Query("SELECT * FROM device_info LIMIT 1")
    suspend fun getDevice(): DeviceEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDevice(device: DeviceEntity)

    @Update
    suspend fun updateDevice(device: DeviceEntity)

    @Query("UPDATE device_info SET storage_total = :total, storage_free = :free, storage_used = :used")
    suspend fun updateStorage(total: Long, free: Long, used: Long)
}
