package uz.iportal.axadmixled.data.local.database.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "playlists")
data class PlaylistEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val description: String?,
    @ColumnInfo(name = "is_active") val isActive: Boolean,
    val priority: Int,
    val duration: Int,
    @ColumnInfo(name = "media_count") val mediaCount: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
    @ColumnInfo(name = "download_status") val downloadStatus: String,
    @ColumnInfo(name = "downloaded_items") val downloadedItems: Int,
    @ColumnInfo(name = "missing_files") val missingFiles: String?, // JSON array
    @ColumnInfo(name = "last_synced_at") val lastSyncedAt: Long?
)
