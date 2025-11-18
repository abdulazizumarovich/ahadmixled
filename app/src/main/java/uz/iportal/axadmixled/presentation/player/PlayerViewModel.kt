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
import uz.iportal.axadmixled.domain.model.DownloadStatus
import uz.iportal.axadmixled.domain.model.Playlist
import uz.iportal.axadmixled.domain.model.TextOverlay
import uz.iportal.axadmixled.domain.model.WebSocketCommand
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import uz.iportal.axadmixled.util.NetworkMonitor
import javax.inject.Inject

@HiltViewModel
class PlayerViewModel @Inject constructor(
    private val playlistRepository: PlaylistRepository,
    private val webSocketManager: WebSocketManager,
    private val deviceRepository: DeviceRepository,
    private val networkMonitor: NetworkMonitor
) : ViewModel() {

    private val _currentPlaylist = MutableStateFlow<Playlist?>(null)
    val currentPlaylist: StateFlow<Playlist?> = _currentPlaylist.asStateFlow()

    private val _playerCommand = MutableSharedFlow<PlayerCommand>()
    val playerCommand: SharedFlow<PlayerCommand> = _playerCommand.asSharedFlow()

    init {
        observeWebSocketCommands()
        observeNetworkChanges()
    }

    private fun observeWebSocketCommands() {
        viewModelScope.launch {
            webSocketManager.commands.collect { command ->
                Timber.d("Received WebSocket command: $command")
                handleWebSocketCommand(command)
            }
        }
    }

    private fun observeNetworkChanges() {
        viewModelScope.launch {
            networkMonitor.isConnected.collect { isConnected ->
                Timber.d("Network status changed: connected=$isConnected")
                if (isConnected) {
                    Timber.d("Network connected, reconnecting WebSocket and syncing playlists")
                    webSocketManager.connect()
                    syncPlaylists()
                }
            }
        }
    }

    fun loadCurrentPlaylist() {
        viewModelScope.launch {
            try {
                Timber.d("Loading current playlist")
                val playlists = playlistRepository.getPlaylists()
                val current = playlists.firstOrNull { it.isActive } ?: playlists.firstOrNull()

                if (current != null) {
                    Timber.d("Loaded playlist: ${current.name} (id=${current.id})")
                    _currentPlaylist.value = current
                } else {
                    Timber.w("No playlists available")
                }
            } catch (e: Exception) {
                Timber.e(e, "Failed to load current playlist")
            }
        }
    }

    private suspend fun handleWebSocketCommand(command: WebSocketCommand) {
        try {
            when (command) {
                is WebSocketCommand.Play -> {
                    Timber.d("Handling Play command")
                    _playerCommand.emit(PlayerCommand.Play)
                }
                is WebSocketCommand.Pause -> {
                    Timber.d("Handling Pause command")
                    _playerCommand.emit(PlayerCommand.Pause)
                }
                is WebSocketCommand.Next -> {
                    Timber.d("Handling Next command")
                    _playerCommand.emit(PlayerCommand.Next)
                }
                is WebSocketCommand.Previous -> {
                    Timber.d("Handling Previous command")
                    _playerCommand.emit(PlayerCommand.Previous)
                }
                is WebSocketCommand.ReloadPlaylist -> {
                    Timber.d("Handling ReloadPlaylist command")
                    reloadPlaylist()
                }
                is WebSocketCommand.SwitchPlaylist -> {
                    Timber.d("Handling SwitchPlaylist command: playlistId=${command.playlistId}")
                    switchPlaylist(command.playlistId)
                }
                is WebSocketCommand.PlayMedia -> {
                    Timber.d("Handling PlayMedia command: mediaId=${command.mediaId}, mediaIndex=${command.mediaIndex}")
                    _playerCommand.emit(
                        PlayerCommand.PlaySpecificMedia(command.mediaId, command.mediaIndex)
                    )
                }
                is WebSocketCommand.ShowTextOverlay -> {
                    Timber.d("Handling ShowTextOverlay command: text=${command.textOverlay.text}")
                    _playerCommand.emit(PlayerCommand.ShowTextOverlay(command.textOverlay))
                }
                is WebSocketCommand.HideTextOverlay -> {
                    Timber.d("Handling HideTextOverlay command")
                    _playerCommand.emit(PlayerCommand.HideTextOverlay)
                }
                is WebSocketCommand.SetBrightness -> {
                    Timber.d("Handling SetBrightness command: brightness=${command.brightness}")
                    _playerCommand.emit(PlayerCommand.SetBrightness(command.brightness))
                }
                is WebSocketCommand.SetVolume -> {
                    Timber.d("Handling SetVolume command: volume=${command.volume}")
                    _playerCommand.emit(PlayerCommand.SetVolume(command.volume))
                }
                is WebSocketCommand.CleanupOldPlaylists -> {
                    Timber.d("Handling CleanupOldPlaylists command: keep=${command.playlistIdsToKeep}")
                    cleanupOldPlaylists(command.playlistIdsToKeep)
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Error handling WebSocket command: $command")
        }
    }

    private suspend fun reloadPlaylist() {
        val currentPlaylist = _currentPlaylist.value
        if (currentPlaylist == null) {
            Timber.w("Cannot reload playlist: no current playlist")
            return
        }

        try {
            Timber.d("Reloading playlist: ${currentPlaylist.id}")
            playlistRepository.downloadPlaylist(currentPlaylist.id)
            loadCurrentPlaylist()
            _playerCommand.emit(PlayerCommand.ReloadCurrentPlaylist)
        } catch (e: Exception) {
            Timber.e(e, "Failed to reload playlist")
        }
    }

    private suspend fun switchPlaylist(playlistId: Int) {
        try {
            Timber.d("Switching to playlist: $playlistId")
            val playlist = playlistRepository.getPlaylist(playlistId)

            if (playlist.downloadStatus != DownloadStatus.READY) {
                Timber.d("Playlist not ready, downloading: $playlistId")
                playlistRepository.downloadPlaylist(playlistId)
            }

            _currentPlaylist.value = playlist
            _playerCommand.emit(PlayerCommand.SwitchPlaylist(playlist))
        } catch (e: Exception) {
            Timber.e(e, "Failed to switch playlist: $playlistId")
        }
    }

    private suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>) {
        try {
            Timber.d("Cleaning up old playlists, keeping: $playlistIdsToKeep")
            playlistRepository.cleanupOldPlaylists(playlistIdsToKeep)
        } catch (e: Exception) {
            Timber.e(e, "Failed to cleanup old playlists")
        }
    }

    private suspend fun syncPlaylists() {
        try {
            Timber.d("Syncing playlists from server")
            playlistRepository.syncPlaylists()
        } catch (e: Exception) {
            Timber.e(e, "Failed to sync playlists")
        }
    }

    override fun onCleared() {
        super.onCleared()
        Timber.d("PlayerViewModel cleared")
    }
}

sealed class PlayerCommand {
    object Play : PlayerCommand()
    object Pause : PlayerCommand()
    object Next : PlayerCommand()
    object Previous : PlayerCommand()
    object ReloadCurrentPlaylist : PlayerCommand()
    data class SwitchPlaylist(val playlist: Playlist) : PlayerCommand()
    data class PlaySpecificMedia(val mediaId: Int?, val mediaIndex: Int?) : PlayerCommand()
    data class ShowTextOverlay(val overlay: TextOverlay) : PlayerCommand()
    object HideTextOverlay : PlayerCommand()
    data class SetBrightness(val brightness: Int) : PlayerCommand()
    data class SetVolume(val volume: Int) : PlayerCommand()
}
