package uz.iportal.axadmixled.domain.model

data class PlaylistStatusMessage(
    val type: String = "playlist_status",
    val playlist_id: Int,
    val status: String, // "ready", "downloading", "partial", "failed"
    val total_items: Int,
    val downloaded_items: Int,
    val missing_files: List<String>? = null,
    val error: String? = null
)

data class ReadyPlaylistsMessage(
    val type: String = "ready_playlists",
    val playlist_ids: List<Int>
)

data class DeviceStatusMessage(
    val type: String = "device_status",
    val sn_number: String,
    val is_online: Boolean,
    val current_playlist_id: Int?,
    val current_media_id: Int?,
    val playback_state: String, // "playing", "paused", "stopped"
    val timestamp: Long = System.currentTimeMillis()
)

data class StorageInfo(
    val totalSpace: Long,
    val freeSpace: Long,
    val usedSpace: Long,
    val usedByApp: Long = 0L,
    val currentPlaylistId: Long = 0L
)
