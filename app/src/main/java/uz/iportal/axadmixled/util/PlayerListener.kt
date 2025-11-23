package uz.iportal.axadmixled.util

import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import timber.log.Timber
import uz.iportal.axadmixled.data.remote.websocket.WebSocketManager
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
@UnstableApi
class PlayerListener @Inject constructor(
    private val webSocketManager: WebSocketManager
) : Player.Listener {

    var queuedPlaylistId: Int? = null
    var playingPlaylistId: Int? = null
        private set
    var playingMediaId: Int? = null
        private set

    var onPlaylistPlaybackError: (Int) -> Unit = {}

    override fun onPlayWhenReadyChanged(
        playWhenReady: Boolean,
        @Player.PlayWhenReadyChangeReason reason: Int
    ) {
        playingMediaId = null
        sendPlaybackState( "queued", playlistId = queuedPlaylistId)
        Timber.tag(TAG).d(
            "Playlist queued: $queuedPlaylistId. play_when_ready = $playWhenReady, " +
                    "reason = ${reason.asPlayWhenReadyChangeReason}"
        )
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (isPlaying) {
            Timber.tag(TAG).d("Started playing playlist: $queuedPlaylistId")
            playingPlaylistId = queuedPlaylistId
            sendPlaybackState("playing")
            playingMediaId = null
        } else {
            Timber.tag(TAG).d("Stopped playing playlist: $playingPlaylistId")
            webSocketManager.sendDeviceStatus(playingPlaylistId, playingMediaId, "stopped")
            playingPlaylistId = null
            playingMediaId = null
        }
    }

    override fun onMediaItemTransition(
        mediaItem: MediaItem?,
        @Player.MediaItemTransitionReason reason: Int
    ) {
        playingMediaId = mediaItem?.mediaId?.toIntOrNull()
        sendPlaybackState("playing")
        Timber.tag(TAG).d(
            "Media item started playing: $playingMediaId, " +
                    "reason = ${reason.asMediaItemTransitionReason}"
        )
    }

    override fun onPlayerError(error: PlaybackException) {
        sendPlaybackState("failed")
        Timber.tag(TAG).e(error, "onPlayerError")
        queuedPlaylistId?.let { onPlaylistPlaybackError(it) }
    }

    private fun sendPlaybackState(state: String, playlistId: Int? = playingPlaylistId ?: queuedPlaylistId) {
        webSocketManager.sendDeviceStatus(playlistId, playingMediaId, state)
    }

    val @Player.PlayWhenReadyChangeReason Int.asPlayWhenReadyChangeReason: String
        get() = when (this) {
            Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST -> "USER_REQUEST"
            Player.PLAY_WHEN_READY_CHANGE_REASON_AUDIO_FOCUS_LOSS -> "AUDIO_FOCUS_LOSS"
            Player.PLAY_WHEN_READY_CHANGE_REASON_AUDIO_BECOMING_NOISY -> "AUDIO_BECOMING_NOISY"
            Player.PLAY_WHEN_READY_CHANGE_REASON_REMOTE -> "REMOTE"
            Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM -> "END_OF_MEDIA_ITEM"
            Player.PLAY_WHEN_READY_CHANGE_REASON_SUPPRESSED_TOO_LONG -> "SUPPRESSED_TOO_LONG"
            else -> "Unknown($this)"
        }

    val @Player.MediaItemTransitionReason Int.asMediaItemTransitionReason: String
        get() = when (this) {
            Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT -> "REPEAT"
            Player.MEDIA_ITEM_TRANSITION_REASON_AUTO -> "AUTO"
            Player.MEDIA_ITEM_TRANSITION_REASON_SEEK -> "SEEK"
            Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED -> "PLAYLIST_CHANGED"
            else -> "Unknown($this)"
        }

    companion object {
        private const val TAG = "PlayerListener"
    }
}