package uz.iportal.axadmixled.data.local.database.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "device_info")
data class DeviceEntity(
    @PrimaryKey val id: Int,
    @ColumnInfo(name = "sn_number") val snNumber: String,
    val name: String,
    val model: String,
    @ColumnInfo(name = "android_version") val androidVersion: String,
    @ColumnInfo(name = "screen_resolution") val screenResolution: String,
    @ColumnInfo(name = "storage_total") val storageTotal: Long,
    @ColumnInfo(name = "storage_free") val storageFree: Long,
    @ColumnInfo(name = "storage_used") val storageUsed: Long,
    @ColumnInfo(name = "is_active") val isActive: Boolean,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "registered_at") val registeredAt: Long
)
