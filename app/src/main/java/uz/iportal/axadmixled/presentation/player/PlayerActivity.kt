package uz.iportal.axadmixled.presentation.player

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import coil.load
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.databinding.ActivityPlayerBinding
import uz.iportal.axadmixled.domain.model.MediaType
import uz.iportal.axadmixled.presentation.player.components.MediaPlayerManager
import java.io.File
import javax.inject.Inject

@AndroidEntryPoint
class PlayerActivity : AppCompatActivity() {

    private lateinit var binding: ActivityPlayerBinding
    private val viewModel: PlayerViewModel by viewModels()

    @Inject
    lateinit var mediaPlayerManager: MediaPlayerManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.d("PlayerActivity onCreate")

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
                    systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
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

            Timber.d("Full screen immersive UI configured")
        } catch (e: Exception) {
            Timber.e(e, "Failed to setup full screen UI")
        }
    }

    private fun initializePlayer() {
        // Load playlist first
        viewModel.loadCurrentPlaylist()
    }

    private fun observeViewModel() {
        // Observe current playlist
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.currentPlaylist.collect { playlist ->
                    if (playlist != null) {
                        Timber.d("Playlist loaded: ${playlist.name}")

                        // Initialize MediaPlayerManager with the playlist
                        try {
                            mediaPlayerManager.initialize(
                                playerView = binding.playerView,
                                overlayView = binding.textOverlayView,
                                playlist = playlist,
                                activity = this@PlayerActivity
                            )
                            Timber.d("MediaPlayerManager initialized successfully")
                        } catch (e: Exception) {
                            Timber.e(e, "Failed to initialize MediaPlayerManager")
                        }
                    } else {
                        Timber.w("No playlist available")
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
                mediaPlayerManager.playbackState.collect { state ->
                    handlePlaybackState(state)
                }
            }
        }
    }

    private fun handlePlayerCommand(command: PlayerCommand) {
        try {
            when (command) {
                is PlayerCommand.Play -> {
                    Timber.d("Handling Play command")
                    mediaPlayerManager.play()
                }
                is PlayerCommand.Pause -> {
                    Timber.d("Handling Pause command")
                    mediaPlayerManager.pause()
                }
                is PlayerCommand.Next -> {
                    Timber.d("Handling Next command")
                    mediaPlayerManager.playNext()
                }
                is PlayerCommand.Previous -> {
                    Timber.d("Handling Previous command")
                    mediaPlayerManager.playPrevious()
                }
                is PlayerCommand.ReloadCurrentPlaylist -> {
                    Timber.d("Handling ReloadCurrentPlaylist command")
                    // Reload will be handled by playlist observation
                    viewModel.loadCurrentPlaylist()
                }
                is PlayerCommand.SwitchPlaylist -> {
                    Timber.d("Handling SwitchPlaylist command: ${command.playlist.name}")
                    mediaPlayerManager.switchPlaylist(command.playlist)
                }
                is PlayerCommand.PlaySpecificMedia -> {
                    Timber.d("Handling PlaySpecificMedia command: mediaId=${command.mediaId}, mediaIndex=${command.mediaIndex}")
                    mediaPlayerManager.playSpecificMedia(command.mediaId, command.mediaIndex)
                }
                is PlayerCommand.ShowTextOverlay -> {
                    Timber.d("Handling ShowTextOverlay command")
                    mediaPlayerManager.showTextOverlay(command.overlay)
                }
                is PlayerCommand.HideTextOverlay -> {
                    Timber.d("Handling HideTextOverlay command")
                    mediaPlayerManager.hideTextOverlay()
                }
                is PlayerCommand.SetBrightness -> {
                    Timber.d("Handling SetBrightness command: ${command.brightness}")
                    mediaPlayerManager.setBrightness(command.brightness)
                }
                is PlayerCommand.SetVolume -> {
                    Timber.d("Handling SetVolume command: ${command.volume}")
                    mediaPlayerManager.setVolume(command.volume)
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Error handling player command: $command")
        }
    }

    private fun handlePlaybackState(state: uz.iportal.axadmixled.presentation.player.components.PlaybackState) {
        try {
            when (state) {
                is uz.iportal.axadmixled.presentation.player.components.PlaybackState.Playing -> {
                    val playlist = viewModel.currentPlaylist.value
                    if (playlist != null && state.mediaIndex < playlist.media.size) {
                        val media = playlist.media[state.mediaIndex]

                        // Handle image display using Coil
                        if (media.mediaType == MediaType.IMAGE) {
                            displayImageWithCoil(media.localPath)
                        } else {
                            hideImageView()
                        }
                    }
                }
                is uz.iportal.axadmixled.presentation.player.components.PlaybackState.Paused -> {
                    Timber.d("Playback paused")
                }
                is uz.iportal.axadmixled.presentation.player.components.PlaybackState.Idle -> {
                    Timber.d("Playback idle")
                    hideImageView()
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Error handling playback state")
        }
    }

    private fun displayImageWithCoil(localPath: String?) {
        if (localPath.isNullOrEmpty()) {
            Timber.w("Cannot display image: localPath is null or empty")
            return
        }

        val file = File(localPath)
        if (!file.exists()) {
            Timber.e("Image file does not exist: $localPath")
            return
        }

        try {
            Timber.d("Displaying image with Coil: $localPath")

            // Hide video player, show image view
            binding.playerView.visibility = View.GONE
            binding.ivImage.visibility = View.VISIBLE

            // Load image with Coil
            binding.ivImage.load(file) {
                crossfade(true)
                error(android.R.drawable.ic_menu_report_image)
                listener(
                    onSuccess = { _, _ ->
                        Timber.d("Image loaded successfully: $localPath")
                    },
                    onError = { _, throwable ->
                        Timber.e(throwable.throwable, "Failed to load image: $localPath")
                    }
                )
            }
        } catch (e: Exception) {
            Timber.e(e, "Error displaying image with Coil")
        }
    }

    private fun hideImageView() {
        binding.ivImage.visibility = View.GONE
        binding.playerView.visibility = View.VISIBLE
    }

    override fun onResume() {
        super.onResume()
        Timber.d("PlayerActivity onResume")

        // Maintain full screen on resume
        setupFullScreenUI()
    }

    override fun onPause() {
        super.onPause()
        Timber.d("PlayerActivity onPause")
    }

    override fun onDestroy() {
        super.onDestroy()
        Timber.d("PlayerActivity onDestroy")

        // Release media player resources
        try {
            mediaPlayerManager.release()
            Timber.d("MediaPlayerManager released")
        } catch (e: Exception) {
            Timber.e(e, "Error releasing MediaPlayerManager")
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
