package uz.iportal.axadmixled.domain.model

import com.google.gson.annotations.SerializedName

data class PlaylistsResponse(

    @field:SerializedName("left_screen")
    val leftScreen: Any? = null,

    @field:SerializedName("sn_number")
    val snNumber: String,

    @field:SerializedName("back_screen")
    val backScreen: Any? = null,

    @field:SerializedName("front_screen")
    val frontScreen: FrontScreen,

    @field:SerializedName("right_screen")
    val rightScreen: Any? = null
)

data class Status(

    @field:SerializedName("is_ready")
    val isReady: Boolean,

    @field:SerializedName("all_downloaded")
    val allDownloaded: Boolean,

    @field:SerializedName("missing_files")
    val missingFiles: List<Any>,

    @field:SerializedName("last_verified")
    val lastVerified: String
)

data class PlaybackConfig(

    @field:SerializedName("background_color")
    val backgroundColor: String,

    @field:SerializedName("repeat")
    val repeat: Boolean,

    @field:SerializedName("repeat_count")
    val repeatCount: Int
)

data class MediaItemsItem(

    @field:SerializedName("timing")
    val timing: Timing,

    @field:SerializedName("n_time_play")
    val nTimePlay: Int,

    @field:SerializedName("local_path")
    val localPath: String,

    @field:SerializedName("media_url")
    val mediaUrl: String,

    @field:SerializedName("downloaded")
    val downloaded: Boolean,

    @field:SerializedName("file_size")
    val fileSize: Int,

    @field:SerializedName("layout")
    val layout: Layout,

    @field:SerializedName("effects")
    val effects: Effects,

    @field:SerializedName("media_item")
    val mediaItem: Int,

    @field:SerializedName("media_type")
    val mediaType: String,

    @field:SerializedName("checksum")
    val checksum: String,

    @field:SerializedName("media_id")
    val mediaId: Int,

    @field:SerializedName("mimetype")
    val mimetype: String,

    @field:SerializedName("media_name")
    val mediaName: String,

    @field:SerializedName("download_date")
    val downloadDate: String,

    @field:SerializedName("order")
    val order: Int
)

data class PlaylistsItem(

    @field:SerializedName("duration")
    val duration: Int,

    @field:SerializedName("media_items")
    val mediaItems: List<MediaItemsItem>,

    @field:SerializedName("count_media_items")
    val countMediaItems: Int,

    @field:SerializedName("playback_config")
    val playbackConfig: PlaybackConfig,

    @field:SerializedName("name")
    val name: String,

    @field:SerializedName("width")
    val width: Int,

    @field:SerializedName("id")
    val id: Int,

    @field:SerializedName("playlist_n_times_play")
    val playlistNTimesPlay: Int,

    @field:SerializedName("height")
    val height: Int,

    @field:SerializedName("status")
    val status: Status
)

data class Timing(

    @field:SerializedName("duration")
    val duration: Int,

    @field:SerializedName("start_time")
    val startTime: Int,

    @field:SerializedName("loop")
    val loop: Boolean
)

data class FrontScreen(

    @field:SerializedName("current_playlist")
    val currentPlaylist: Int,

    @field:SerializedName("screen_name")
    val screenName: String,

    @field:SerializedName("playlists")
    val playlists: List<PlaylistsItem>,

    @field:SerializedName("screen_id")
    val screenId: Int,

    @field:SerializedName("resolution")
    val resolution: String,

    @field:SerializedName("count_playlist")
    val countPlaylist: Int
)

data class Effects(

    @field:SerializedName("fade_duration")
    val fadeDuration: Int,

    @field:SerializedName("transition")
    val transition: String
)

data class Layout(

    @field:SerializedName("z_index")
    val zIndex: Int,

    @field:SerializedName("x")
    val x: Int,

    @field:SerializedName("width")
    val width: Int,

    @field:SerializedName("y")
    val y: Int,

    @field:SerializedName("height")
    val height: Int
)
