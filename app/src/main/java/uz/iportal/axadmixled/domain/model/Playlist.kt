package uz.iportal.axadmixled.domain.model

data class Playlist(
    val id: Int,
    val name: String,
    val description: String?,
    val isActive: Boolean,
    val priority: Int,
    val duration: Int, // Total duration in seconds
    val mediaCount: Int,
    val createdAt: String,
    val updatedAt: String,
    val media: List<Media> = emptyList(),

    // Local fields
    val downloadStatus: DownloadStatus = DownloadStatus.PENDING,
    val downloadedItems: Int = 0,
    val missingFiles: List<String> = emptyList(),
    val lastSyncedAt: Long? = null
)

data class PlaylistResponse(
    val count: Int,
    val next: String?,
    val previous: String?,
    val results: List<PlaylistDetail>
)

data class PlaylistDetail(
    val id: Int,
    val name: String,
    val description: String?,
    val isActive: Boolean,
    val priority: Int,
    val duration: Int,
    val mediaCount: Int,
    val media: List<MediaDetail>,
    val createdAt: String,
    val updatedAt: String
)

enum class DownloadStatus {
    PENDING,
    DOWNLOADING,
    READY,
    PARTIAL,
    FAILED
}
