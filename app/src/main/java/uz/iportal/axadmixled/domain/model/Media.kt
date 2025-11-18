package uz.iportal.axadmixled.domain.model

data class Media(
    val id: Int,
    val name: String,
    val description: String?,
    val file: String, // URL to media file
    val thumbnail: String?, // URL to thumbnail
    val mediaType: MediaType,
    val duration: Int, // Duration in seconds (for video) or display time (for image)
    val fileSize: Long,
    val resolution: String?, // e.g., "1920x1080"
    val checksum: String?,
    val order: Int, // Order in playlist
    val createdAt: String,
    val updatedAt: String,

    // Local fields
    val localPath: String? = null,
    val isDownloaded: Boolean = false,
    val downloadedAt: Long? = null,
    val downloadProgress: Int = 0
)

data class MediaDetail(
    val id: Int,
    val name: String,
    val description: String?,
    val file: String,
    val thumbnail: String?,
    val mediaType: String, // "video" or "image"
    val duration: Int,
    val fileSize: Long,
    val resolution: String?,
    val checksum: String?,
    val order: Int,
    val createdAt: String,
    val updatedAt: String
)

enum class MediaType {
    VIDEO,
    IMAGE;

    companion object {
        fun fromString(type: String): MediaType {
            return when (type.lowercase()) {
                "video" -> VIDEO
                "image" -> IMAGE
                else -> VIDEO
            }
        }
    }
}
