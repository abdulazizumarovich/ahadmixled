package uz.iportal.axadmixled.presentation.player

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.data.remote.websocket.WebSocketManager
import uz.iportal.axadmixled.domain.model.Playlist
import uz.iportal.axadmixled.domain.model.TextOverlay
import uz.iportal.axadmixled.domain.model.WebSocketCommand
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import uz.iportal.axadmixled.util.NetworkMonitor
import uz.iportal.axadmixled.util.PlayerListener
import javax.inject.Inject

private const val TAG = "PlayerViewModel"

@HiltViewModel
class PlayerViewModel @Inject constructor(
    private val playlistRepository: PlaylistRepository,
    private val webSocketManager: WebSocketManager,
    private val networkMonitor: NetworkMonitor,
    playerListener: PlayerListener
) : ViewModel() {

    private val _currentPlaylist = MutableStateFlow<Playlist?>(null)
    val currentPlaylist: StateFlow<Playlist?> = _currentPlaylist.asStateFlow()

    private val _playerCommand = MutableSharedFlow<PlayerCommand>()
    val playerCommand: SharedFlow<PlayerCommand> = _playerCommand.asSharedFlow()

    init {
        observeWebSocketCommands()
        observeNetworkChanges()
        playerListener.onPlaylistPlaybackError = { playlistId ->
            viewModelScope.launch {
                playlistRepository.deactivatePlaylist(playlistId)
                loadCurrentPlaylist()
            }
        }
    }

    private fun observeWebSocketCommands() {
        viewModelScope.launch {
            webSocketManager.commands.collect { command ->
                Timber.tag(TAG).d("Received WebSocket command: $command")
                handleWebSocketCommand(command)
            }
        }
    }

    private fun observeNetworkChanges() {
        viewModelScope.launch {
            networkMonitor.isConnected.collect { isConnected ->
                Timber.tag(TAG).d("Network status changed: connected=$isConnected")
                if (isConnected) {
                    Timber.tag(TAG).d("Network connected, reconnecting WebSocket and syncing playlists")
                    webSocketManager.connect()
                    syncPlaylists()
                    downloadPlaylists()
                }
            }
        }
    }

    fun loadCurrentPlaylist() {
        viewModelScope.launch {
            try {
                Timber.tag(TAG).d("Loading current playlist")
                val playlist = playlistRepository.getActivePlaylist()
                if (playlist != null) {
                    _currentPlaylist.value = playlist
                } else {
                    Timber.tag(TAG).w("No playlists available")
                }
            } catch (e: Exception) {
                Timber.tag(TAG).e(e, "Failed to load current playlist")
            }
        }
    }

    private suspend fun handleWebSocketCommand(command: WebSocketCommand) {
        try {
            when (command) {
                is WebSocketCommand.Play -> {
                    Timber.tag(TAG).d("Handling Play command")
                    _playerCommand.emit(PlayerCommand.Play)
                }
                is WebSocketCommand.Pause -> {
                    Timber.tag(TAG).d("Handling Pause command")
                    _playerCommand.emit(PlayerCommand.Pause)
                }
                is WebSocketCommand.Next -> {
                    Timber.tag(TAG).d("Handling Next command")
                    _playerCommand.emit(PlayerCommand.Next)
                }
                is WebSocketCommand.Previous -> {
                    Timber.tag(TAG).d("Handling Previous command")
                    _playerCommand.emit(PlayerCommand.Previous)
                }
                is WebSocketCommand.ReloadPlaylist -> {
                    Timber.tag(TAG).d("Handling ReloadPlaylist command")
                    reloadPlaylist()
                }
                is WebSocketCommand.SwitchPlaylist -> {
                    Timber.tag(TAG).d("Handling SwitchPlaylist command: playlistId=${command.playlistId}")
                    switchPlaylist(command.playlistId)
                }
                is WebSocketCommand.PlayMedia -> {
                    Timber.tag(TAG).d("Handling PlayMedia command: mediaId=${command.mediaId}, mediaIndex=${command.mediaIndex}")
                    _playerCommand.emit(
                        PlayerCommand.PlaySpecificMedia(command.mediaId, command.mediaIndex)
                    )
                }
                is WebSocketCommand.ShowTextOverlay -> {
                    Timber.tag(TAG).d("Handling ShowTextOverlay command: text=${command.textOverlay.text}")
                    _playerCommand.emit(PlayerCommand.ShowTextOverlay(command.textOverlay))
                }
                is WebSocketCommand.HideTextOverlay -> {
                    Timber.tag(TAG).d("Handling HideTextOverlay command")
                    _playerCommand.emit(PlayerCommand.HideTextOverlay)
                }
                is WebSocketCommand.SetBrightness -> {
                    Timber.tag(TAG).d("Handling SetBrightness command: brightness=${command.brightness}")
                    _playerCommand.emit(PlayerCommand.SetBrightness(command.brightness))
                }
                is WebSocketCommand.SetVolume -> {
                    Timber.tag(TAG).d("Handling SetVolume command: volume=${command.volume}")
                    _playerCommand.emit(PlayerCommand.SetVolume(command.volume))
                }
                is WebSocketCommand.CleanupOldPlaylists -> {
                    Timber.tag(TAG).d("Handling CleanupOldPlaylists command: keep=${command.playlistIdsToKeep}")
                    cleanupOldPlaylists(command.playlistIdsToKeep)
                }
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error handling WebSocket command: $command")
        }
    }

    private suspend fun reloadPlaylist(playlistId: Int? = null) {
        val playlistIdToReload = playlistId ?: _currentPlaylist.value?.id
        if (playlistIdToReload == null) {
            Timber.tag(TAG).e("Reloading playlist failed, neither new playlist is not specified not current playlist is available")
            return
        }

        try {
            Timber.tag(TAG).d("Reloading playlist: $playlistIdToReload")
            playlistRepository.syncPlaylists(forceRenew = true)
            loadCurrentPlaylist()
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to reload playlist")
        }
    }

    private suspend fun switchPlaylist(playlistId: Int) {
        try {
            Timber.tag(TAG).d("Switching to playlist: $playlistId")
            val playlist = playlistRepository.switchPlaylist(playlistId)
            if (playlist == null) {
                Timber.tag(TAG).e("No playlist found for: $playlistId")
                return
            }

            _currentPlaylist.value = playlist
//            _playerCommand.emit(PlayerCommand.SwitchPlaylist(playlist))
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to switch playlist: $playlistId")
        }
    }

    private suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>) {
        try {
            Timber.tag(TAG).d("Cleaning up old playlists, keeping: $playlistIdsToKeep")
            playlistRepository.cleanupOldPlaylists(playlistIdsToKeep)
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to cleanup old playlists")
        }
    }

    private suspend fun syncPlaylists() {
        try {
            Timber.tag(TAG).d("Syncing playlists from server")
            playlistRepository.syncPlaylists()
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to sync playlists")
        }
    }

    private suspend fun downloadPlaylists() {
        try {
            Timber.tag(TAG).d("Downloading playlists to local")
            playlistRepository.downloadRemainingPlaylistsInBackground()
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to download playlists")
        }
    }

    override fun onCleared() {
        super.onCleared()
        Timber.tag(TAG).d("PlayerViewModel cleared")
    }
}

sealed class PlayerCommand {
    object Play : PlayerCommand()
    object Pause : PlayerCommand()
    object Next : PlayerCommand()
    object Previous : PlayerCommand()
    data class SwitchPlaylist(val playlist: Playlist) : PlayerCommand()
    data class PlaySpecificMedia(val mediaId: Int?, val mediaIndex: Int?) : PlayerCommand()
    data class ShowTextOverlay(val overlay: TextOverlay) : PlayerCommand()
    object HideTextOverlay : PlayerCommand()
    data class SetBrightness(val brightness: Int) : PlayerCommand()
    data class SetVolume(val volume: Int) : PlayerCommand()
}
