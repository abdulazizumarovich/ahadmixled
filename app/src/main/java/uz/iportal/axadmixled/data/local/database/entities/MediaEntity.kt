package uz.iportal.axadmixled.data.local.database.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "media",
    foreignKeys = [
        ForeignKey(
            entity = PlaylistEntity::class,
            parentColumns = ["id"],
            childColumns = ["playlist_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("playlist_id"), Index("order")]
)
data class MediaEntity(
    @PrimaryKey val id: Int,
    @ColumnInfo(name = "playlist_id") val playlistId: Int,
    val name: String,
    val description: String?,
    val file: String, // Remote URL
    val thumbnail: String?,
    @ColumnInfo(name = "media_type") val mediaType: String,
    val duration: Int,
    @ColumnInfo(name = "file_size") val fileSize: Long,
    val resolution: String?,
    val checksum: String?,
    val order: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
    @ColumnInfo(name = "local_path") val localPath: String?,
    @ColumnInfo(name = "is_downloaded") val isDownloaded: Boolean,
    @ColumnInfo(name = "downloaded_at") val downloadedAt: Long?,
    @ColumnInfo(name = "download_progress") val downloadProgress: Int
)
