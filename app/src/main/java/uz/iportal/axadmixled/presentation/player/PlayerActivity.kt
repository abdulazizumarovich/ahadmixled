package uz.iportal.axadmixled.presentation.player

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.annotation.OptIn
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import coil.load
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.databinding.ActivityPlayerBinding
import uz.iportal.axadmixled.domain.model.MediaType
import uz.iportal.axadmixled.domain.model.Playlist
import uz.iportal.axadmixled.presentation.player.components.PlaybackState
import uz.iportal.axadmixled.util.PlayerListener
import uz.iportal.axadmixled.util.localPathToUri
import javax.inject.Inject
import javax.inject.Provider

private const val TAG = "PlayerActivity"

@UnstableApi
@AndroidEntryPoint
class PlayerActivity : AppCompatActivity() {

    private lateinit var binding: ActivityPlayerBinding
    private val viewModel: PlayerViewModel by viewModels()
    private var exoPlayer: ExoPlayer? = null
//    private var mediaList = emptyList<List<Playlist>>()

    @Inject
    lateinit var exoPlayerProvider: Provider<ExoPlayer>

    @Inject
    lateinit var playerListener: PlayerListener

    @OptIn(UnstableApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.tag(TAG).d("PlayerActivity onCreate")

        // Setup ViewBinding
        binding = ActivityPlayerBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Setup full screen and immersive UI
        setupFullScreenUI()

        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Load current playlist and initialize player
        initializePlayer()

        // Observe ViewModel
        observeViewModel()
    }

    private fun setupFullScreenUI() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11 and above
                window.setDecorFitsSystemWindows(false)
                window.insetsController?.apply {
                    hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                    systemBarsBehavior =
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                // Android 10 and below
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_FULLSCREEN
                                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        )
            }

            Timber.tag(TAG).d("Full screen immersive UI configured")
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to setup full screen UI")
        }
    }

    private fun initializePlayer() {
        // Load playlist first
        viewModel.loadCurrentPlaylist()

        binding.playerView.hideController() // Hide controller UI
        binding.playerView.useController = false
    }

    @UnstableApi
    private fun observeViewModel() {
        // Observe current playlist
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.currentPlaylist.collect { playlist ->
//                    Timber.tag(TAG).d("Playlist COUNT: ${playlist?.id}")
                    if (playlist == null) {
                        playerListener.queuedPlaylistId = null
                        Timber.tag(TAG).w("No playlist available")
                        binding.progress.visibility = View.VISIBLE
                        return@collect
                    }
                //                        mediaList = playlist.filterNotNull()
                //                        Timber.tag(TAG).d("Playlist loaded: ${playlist.name}")
                        // Initialize MediaPlayerManager with the playlist
                    try {
                        exoPlayer?.stop()
                        exoPlayer?.release()

                        playerListener.queuedPlaylistId = playlist.id
                        exoPlayer = exoPlayerProvider.get()

                        binding.playerView.player = exoPlayer

                        val mediaItems = playlist.mediaItems
                        if (mediaItems.isEmpty()) {
                            Timber.tag(TAG).e("Playlist has no media")
                            return@collect
                        }

                        exoPlayer?.apply {
                            setMediaItems(mediaItems)
                            prepare()
                            play()
                        }

                        binding.progress.visibility = View.GONE
                        Timber.tag(TAG).d("MediaPlayerManager initialized successfully")
                    } catch (e: Exception) {
                        Timber.tag(TAG)
                            .e(e, "Failed to initialize MediaPlayerManager")
                    }
                }
            }
        }

        // Observe player commands
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.playerCommand.collect { command ->
                    handlePlayerCommand(command)
                }
            }
        }

        // Observe playback state for image display
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
//                mediaPlayerManager.playbackState.collect { state ->
//                    handlePlaybackState(state)
//                }
            }
        }
    }

    private val Playlist.mediaItems: List<MediaItem>
        get() = media.filter { it.mediaType != MediaType.IMAGE && it.isDownloaded }
            .map { it.id to it.localPath.localPathToUri() }
            .filter { it.second != null }
            .map {
                Timber.tag(TAG).d("MediaItem from file: $it")
                MediaItem.Builder()
                    .setMediaId(it.first.toString())
                    .setUri(it.second)
                    .build()
            }

    @OptIn(UnstableApi::class)
    private fun handlePlayerCommand(command: PlayerCommand) {
        try {
            when (command) {
                is PlayerCommand.Play -> {
                    Timber.tag("PlayerCommand").d("Handling Play command")
                    exoPlayer?.play()
//                    mediaPlayerManager.play()
                }

                is PlayerCommand.Pause -> {
                    Timber.tag("PlayerCommand").d("Handling Pause command")
                    exoPlayer?.pause()
//                    mediaPlayerManager.pause()
                }

                is PlayerCommand.Next -> {
                    Timber.tag("PlayerCommand").d("Handling Next command")
                    binding.playerView.player?.seekForward()
//                    if (exoPlayer?.hasNextMediaItem() == true) {
//                        exoPlayer?.getMediaItemAt((exoPlayer?.currentMediaItemIndex ?: -1) + 1)
//                    }
//                    mediaPlayerManager.playNext()
                    exoPlayer?.let { exoPlayer ->
                        val currentIndex = exoPlayer.currentMediaItemIndex
                        val nextIndex = currentIndex + 1

                        if (nextIndex < exoPlayer.mediaItemCount) {
                            exoPlayer.seekTo(nextIndex, 0)
                            if (exoPlayer.isPlaying) {
                                exoPlayer.playWhenReady = true
                            }
                        }
                    }
                }

                is PlayerCommand.Previous -> {
                    Timber.tag("PlayerCommand").d("Handling Previous command")
                    exoPlayer?.let { exoPlayer ->
                        val currentIndex = exoPlayer.currentMediaItemIndex
                        val prevIndex = currentIndex - 1

                        if (prevIndex >= 0) {
                            exoPlayer.seekTo(prevIndex, 0)
                            if (exoPlayer.isPlaying) {
                                exoPlayer.playWhenReady = true
                            }
                        }

                    }

//                    if (exoPlayer?.hasPrevious() == true) {
//                        exoPlayer?.seekBack()
//                    }
                }

                is PlayerCommand.SwitchPlaylist -> {
                    Timber.tag("PlayerCommand")
                        .d("Handling SwitchPlaylist command: ${command.playlist.name}")
//                    mediaPlayerManager.switchPlaylist(command.playlist)
                }

                is PlayerCommand.PlaySpecificMedia -> {
                    Timber.tag("PlayerCommand")
                        .d("Handling PlaySpecificMedia command: mediaId=${command.mediaId}, mediaIndex=${command.mediaIndex}")
//                    mediaPlayerManager.playSpecificMedia(command.mediaId, command.mediaIndex)
                }

                is PlayerCommand.ShowTextOverlay -> {
                    Timber.tag("PlayerCommand").d("Handling ShowTextOverlay command")
                    binding.textOverlayView.show(command.overlay)
//                    mediaPlayerManager.showTextOverlay(command.overlay)
                }

                is PlayerCommand.HideTextOverlay -> {
                    Timber.tag("PlayerCommand").d("Handling HideTextOverlay command")
                    binding.textOverlayView.hide()

//                    mediaPlayerManager.hideTextOverlay()
                }

                is PlayerCommand.SetBrightness -> {
                    Timber.tag("PlayerCommand")
                        .d("Handling SetBrightness command: ${command.brightness}")
                    setBrightness(command.brightness)
                }

                is PlayerCommand.SetVolume -> {
                    Timber.tag("PlayerCommand").d("Handling SetVolume command: ${command.volume}")
//                    mediaPlayerManager.setVolume(command.volume)
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Error handling player command: $command")
        }
    }

    private fun setBrightness(level: Int) {
        try {
            val brightness = (level.coerceIn(0, 100) / 100f)
            Timber.d("Setting brightness to $level% ($brightness)")

            val layoutParams = window.attributes
            layoutParams.screenBrightness = brightness
            window.attributes = layoutParams
        } catch (e: Exception) {
            Timber.e(e, "Failed to set brightness")
        }
    }

    private fun handlePlaybackState(state: PlaybackState) {
        try {
            when (state) {
                is PlaybackState.Playing -> {
                    val playlist = viewModel.currentPlaylist.value
                    if (playlist != null && state.mediaIndex < (playlist.media.size ?: 0)
                    ) {
                        val media = playlist.media[state.mediaIndex]

                        // Handle image display using Coil
                        if (media?.mediaType == MediaType.IMAGE) {
                            displayImageWithCoil(media.localPath)
                        } else {
                            hideImageView()
                        }
                    }
                }

                is PlaybackState.Paused -> {
                    Timber.tag(TAG).d("Playback paused")
                }

                is PlaybackState.Idle -> {
                    Timber.tag(TAG).d("Playback idle")
                    hideImageView()
                }
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error handling playback state")
        }
    }

    private fun displayImageWithCoil(localPath: String?) {
        if (localPath.isNullOrEmpty()) {
            Timber.w("Cannot display image: localPath is null or empty")
            return
        }

//        val file = File(localPath)
//        if (!file.exists()) {
//            Timber.e("Image file does not exist: $localPath")
//            return
//        }

        try {
            Timber.tag(TAG).d("Displaying image with Coil: $localPath")

            // Hide video player, show image view
            binding.playerView.visibility = View.GONE
            binding.ivImage.visibility = View.VISIBLE

            // Load image with Coil
            binding.ivImage.load(localPath) {
                crossfade(true)
                error(android.R.drawable.ic_menu_report_image)
                listener(
                    onSuccess = { _, _ ->
                        Timber.tag(TAG).d("Image loaded successfully: $localPath")
                    },
                    onError = { _, throwable ->
                        Timber.tag(TAG)
                            .e(throwable.throwable, "Failed to load image: $localPath")
                    }
                )
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error displaying image with Coil")
        }
    }

    private fun hideImageView() {
        binding.ivImage.visibility = View.GONE
        binding.playerView.visibility = View.VISIBLE
    }

    override fun onResume() {
        super.onResume()
        Timber.tag(TAG).d("PlayerActivity onResume")

        // Maintain full screen on resume
        setupFullScreenUI()
    }

    override fun onDestroy() {
        super.onDestroy()
        Timber.tag(TAG).d("PlayerActivity onDestroy")

        // Release media player resources
        try {
            exoPlayer?.stop()
            exoPlayer?.release()
//            mediaPlayerManager.release()
            Timber.tag(TAG).d("MediaPlayerManager released")
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error releasing MediaPlayerManager")
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Re-apply immersive mode when window regains focus
            setupFullScreenUI()
        }
    }
}
