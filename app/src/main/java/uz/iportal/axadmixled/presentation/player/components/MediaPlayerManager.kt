package uz.iportal.axadmixled.presentation.player.components

import android.app.Activity
import android.content.Context
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.data.remote.websocket.WebSocketManager
import uz.iportal.axadmixled.domain.model.Media
import uz.iportal.axadmixled.domain.model.MediaType
import uz.iportal.axadmixled.domain.model.Playlist
import uz.iportal.axadmixled.domain.model.TextOverlay
import uz.iportal.axadmixled.domain.repository.ScreenshotRepository
import uz.iportal.axadmixled.util.ScreenshotCapture
import java.io.File
import javax.inject.Inject

class MediaPlayerManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val webSocketManager: WebSocketManager,
    private val screenshotCapture: ScreenshotCapture,
    private val screenshotRepository: ScreenshotRepository
) {
    private var exoPlayer: ExoPlayer? = null
    private var currentPlaylist: Playlist? = null
    private var currentMediaIndex: Int = 0
    private var textOverlayView: TextOverlayView? = null
    private var imageDisplayJob: Job? = null
    private var playerView: PlayerView? = null
    private var activity: Activity? = null

    private val _playbackState = MutableStateFlow<PlaybackState>(PlaybackState.Idle)
    val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()

    fun initialize(
        playerView: PlayerView,
        overlayView: TextOverlayView,
        playlist: Playlist,
        activity: Activity
    ) {
        Timber.d("Initializing MediaPlayerManager with playlist: ${playlist.name}")
        this.playerView = playerView
        this.activity = activity
        currentPlaylist = playlist
        currentMediaIndex = 0
        textOverlayView = overlayView

        // Initialize ExoPlayer
        exoPlayer = ExoPlayer.Builder(context).build().apply {
            playerView.player = this
            addListener(createPlayerListener())
        }

        playCurrentMedia()
    }

    private fun createPlayerListener(): Player.Listener {
        return object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_ENDED -> {
                        Timber.d("Video playback ended, playing next")
                        playNext()
                    }
                    Player.STATE_READY -> {
                        Timber.d("Player ready")
                    }
                    Player.STATE_BUFFERING -> {
                        Timber.d("Player buffering")
                    }
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                Timber.e(error, "Playback error occurred")
                playNext()
            }
        }
    }

    private fun playCurrentMedia() {
        val playlist = currentPlaylist
        if (playlist == null) {
            Timber.tag("PLAYERSCREEN").w("Cannot play media: no playlist loaded")
            return
        }

        if (playlist.media.isEmpty()) {
            Timber.tag("PLAYERSCREEN").w("Cannot play media: playlist is empty")
            return
        }

        val media = playlist.media[currentMediaIndex]
        Timber.tag("PLAYERSCREEN").d("Playing media: ${media.name} (type=${media.mediaType}, index=$currentMediaIndex)")

        when (media.mediaType) {
            MediaType.VIDEO -> playVideo(media)
            MediaType.IMAGE -> displayImage(media)
        }

        updatePlaybackState(
            PlaybackState.Playing(
                playlistId = playlist.id,
                mediaId = media.id,
                mediaIndex = currentMediaIndex
            )
        )

        sendDeviceStatus("playing", playlist.id, media.id)
        captureAndUploadScreenshot(media)
    }

    private fun playVideo(media: Media) {
        val localPath = media.localPath
        if (localPath.isNullOrEmpty()) {
            Timber.tag("PLAYERSCREEN").e("Video local path is null for media ${media.id}")
            playNext()
            return
        }

        val file = File(localPath)
        if (!file.exists()) {
            Timber.tag("PLAYERSCREEN").e("Video file does not exist: $localPath")
            playNext()
            return
        }

        try {
            // Cancel any running image display job
            imageDisplayJob?.cancel()

            // Show player view, hide image view
            playerView?.visibility = android.view.View.VISIBLE

            val mediaItem = MediaItem.fromUri(Uri.fromFile(file))
            exoPlayer?.apply {
                setMediaItem(mediaItem)
                prepare()
                playWhenReady = true
            }

            Timber.tag("PLAYERSCREEN").d("Started video playback: ${file.absolutePath}")
        } catch (e: Exception) {
            Timber.tag("PLAYERSCREEN").e(e, "Failed to play video: ${media.name}")
            playNext()
        }
    }

    private fun displayImage(media: Media) {
        val localPath = media.localPath
        if (localPath.isNullOrEmpty()) {
            Timber.e("Image local path is null for media ${media.id}")
            playNext()
            return
        }

        val file = File(localPath)
        if (!file.exists()) {
            Timber.e("Image file does not exist: $localPath")
            playNext()
            return
        }

        try {
            // Stop video player
            exoPlayer?.stop()
            playerView?.visibility = android.view.View.GONE

            // TODO: Display image using ImageView with Coil/Glide
            // For now, just wait for duration
            imageDisplayJob?.cancel()
            imageDisplayJob = CoroutineScope(Dispatchers.Main).launch {
                Timber.d("Displaying image for ${media.duration} seconds: ${file.absolutePath}")
                delay(media.duration * 1000L)
                playNext()
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to display image: ${media.name}")
            playNext()
        }
    }

    fun playNext() {
        val playlist = currentPlaylist ?: return
        if (playlist.media.isEmpty()) return

        currentMediaIndex = (currentMediaIndex + 1) % playlist.media.size
        Timber.d("Playing next media (index=$currentMediaIndex)")
//        playCurrentMedia()
    }

    fun playPrevious() {
        val playlist = currentPlaylist ?: return
        if (playlist.media.isEmpty()) return

        currentMediaIndex = if (currentMediaIndex == 0) {
            playlist.media.size - 1
        } else {
            currentMediaIndex - 1
        }
        Timber.d("Playing previous media (index=$currentMediaIndex)")
        playCurrentMedia()
    }

    fun play() {
        Timber.d("Resuming playback")
        exoPlayer?.playWhenReady = true
        sendDeviceStatus("playing", currentPlaylist?.id, currentPlaylist?.media?.get(currentMediaIndex)?.id)
    }

    fun pause() {
        Timber.d("Pausing playback")
        exoPlayer?.playWhenReady = false

        val playlist = currentPlaylist ?: return
        if (playlist.media.isEmpty()) return

        val media = playlist.media[currentMediaIndex]
        updatePlaybackState(
            PlaybackState.Paused(
                playlistId = playlist.id,
                mediaId = media.id,
                mediaIndex = currentMediaIndex
            )
        )

        sendDeviceStatus("paused", playlist.id, media.id)
    }

    fun switchPlaylist(playlist: Playlist) {
        Timber.d("Switching to playlist: ${playlist.name} (id=${playlist.id})")
        currentPlaylist = playlist
        currentMediaIndex = 0
        playCurrentMedia()
    }

    fun playSpecificMedia(mediaId: Int?, mediaIndex: Int?) {
        val playlist = currentPlaylist ?: return

        if (playlist.media.isEmpty()) return

        val index = when {
            mediaIndex != null -> {
                Timber.d("Playing media by index: $mediaIndex")
                mediaIndex
            }
            mediaId != null -> {
                Timber.d("Playing media by ID: $mediaId")
                playlist.media.indexOfFirst { it.id == mediaId }
            }
            else -> {
                Timber.w("Cannot play media: no mediaId or mediaIndex provided")
                return
            }
        }

        if (index in playlist.media.indices) {
            currentMediaIndex = index
            playCurrentMedia()
        } else {
            Timber.w("Invalid media index: $index (playlist size=${playlist.media.size})")
        }
    }

    fun showTextOverlay(overlay: TextOverlay) {
        Timber.d("Showing text overlay: ${overlay.text}")
        textOverlayView?.show(overlay)
    }

    fun hideTextOverlay() {
        Timber.d("Hiding text overlay")
        textOverlayView?.hide()
    }

    fun setBrightness(level: Int) {
        val activity = this.activity
        if (activity == null) {
            Timber.w("Cannot set brightness: no activity reference")
            return
        }

        try {
            val brightness = (level.coerceIn(0, 100) / 100f)
            Timber.d("Setting brightness to $level% ($brightness)")

            val layoutParams = activity.window.attributes
            layoutParams.screenBrightness = brightness
            activity.window.attributes = layoutParams
        } catch (e: Exception) {
            Timber.e(e, "Failed to set brightness")
        }
    }

    fun setVolume(level: Int) {
        val volume = (level.coerceIn(0, 100) / 100f)
        Timber.d("Setting volume to $level% ($volume)")
        exoPlayer?.volume = volume
    }

    private fun updatePlaybackState(state: PlaybackState) {
        _playbackState.value = state
    }

    private fun sendDeviceStatus(state: String, playlistId: Int?, mediaId: Int?) {
        try {
            webSocketManager.sendDeviceStatus(
                currentPlaylistId = playlistId,
                currentMediaId = mediaId,
                playbackState = state
            )
        } catch (e: Exception) {
            Timber.e(e, "Failed to send device status")
        }
    }

    private fun captureAndUploadScreenshot(media: Media) {
        val activity = this.activity ?: return

        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Wait 1 second for media to start playing
                delay(1000)

                Timber.d("Capturing screenshot for media ${media.id}")
                val screenshotFile = screenshotCapture.captureScreen(activity)

                if (screenshotFile != null) {
                    Timber.d("Uploading screenshot for media ${media.id}")
                    screenshotRepository.uploadScreenshot(
                        mediaId = media.id,
                        screenshotFile = screenshotFile
                    )
                    Timber.d("Screenshot uploaded successfully for media ${media.id}")
                } else {
                    Timber.w("Failed to capture screenshot for media ${media.id}")
                }
            } catch (e: Exception) {
                Timber.e(e, "Failed to capture/upload screenshot for media ${media.id}")
            }
        }
    }

    fun release() {
        Timber.d("Releasing MediaPlayerManager")
        imageDisplayJob?.cancel()
        exoPlayer?.release()
        exoPlayer = null
        textOverlayView = null
        playerView = null
        activity = null
        updatePlaybackState(PlaybackState.Idle)
    }
}

sealed class PlaybackState {
    object Idle : PlaybackState()
    data class Playing(
        val playlistId: Int,
        val mediaId: Int,
        val mediaIndex: Int
    ) : PlaybackState()
    data class Paused(
        val playlistId: Int,
        val mediaId: Int,
        val mediaIndex: Int
    ) : PlaybackState()
}
