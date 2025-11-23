package uz.iportal.axadmixled.domain.model

import com.google.gson.annotations.SerializedName

sealed class WebSocketCommand {
    object Play : WebSocketCommand()
    object Pause : WebSocketCommand()
    object Next : WebSocketCommand()
    object Previous : WebSocketCommand()
    data class ReloadPlaylist(val newPlaylist: Int? = null) : WebSocketCommand()
    data class SwitchPlaylist(val playlistId: Int) : WebSocketCommand()
    data class PlayMedia(val mediaId: Int?, val mediaIndex: Int?) : WebSocketCommand()
    data class ShowTextOverlay(val textOverlay: TextOverlay) : WebSocketCommand()
    object HideTextOverlay : WebSocketCommand()
    data class SetBrightness(val brightness: Int) : WebSocketCommand()
    data class SetVolume(val volume: Int) : WebSocketCommand()
    data class CleanupOldPlaylists(val playlistIdsToKeep: List<Int>) : WebSocketCommand()
}

data class WebSocketCommandDto(
    val action: String,
    @SerializedName("playlist_id")
    val playlistId: Int? = null,
    val mediaId: Int? = null,
    val mediaIndex: Int? = null,
    @SerializedName("params")
    val parameters: Map<String, Any>? = null,
    @SerializedName("text_overlay")
    val textOverlay: TextOverlayDto? = null,
    val brightness: Int? = null,
    val volume: Int? = null,
    val playlistIdsToKeep: List<Int>? = null
)

data class TextOverlay(
    val text: String,
    val position: TextPosition = TextPosition.BOTTOM,
    val animation: TextAnimation = TextAnimation.SCROLL,
    val speed: Float = 50f,
    val fontSize: Int = 24,
    val backgroundColor: String = "#000000",
    val textColor: String = "#FFFFFF"
)

data class TextOverlayDto(
    val text: String,
    val position: String? = "bottom",
    val animation: String? = "scroll",
    val speed: Float? = 50f,
    val font_size: Int? = 24,
    val background_color: String? = "#000000",
    val text_color: String? = "#FFFFFF"
)

enum class TextPosition {
    TOP, BOTTOM, LEFT, RIGHT;

    companion object {
        fun fromString(position: String): TextPosition {
            return when (position.lowercase()) {
                "top" -> TOP
                "bottom" -> BOTTOM
                "left" -> LEFT
                "right" -> RIGHT
                else -> BOTTOM
            }
        }
    }
}

enum class TextAnimation {
    SCROLL, STATIC;

    companion object {
        fun fromString(animation: String): TextAnimation {
            return when (animation.lowercase()) {
                "scroll" -> SCROLL
                "static" -> STATIC
                else -> SCROLL
            }
        }
    }
}
