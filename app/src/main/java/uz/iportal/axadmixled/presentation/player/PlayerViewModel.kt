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
                Timber.tag("PLAYLIST").d("Received WebSocket command: $command")
                handleWebSocketCommand(command)
            }
        }
    }

    private fun observeNetworkChanges() {
        viewModelScope.launch {
            networkMonitor.isConnected.collect { isConnected ->
                Timber.tag("PLAYLIST").d("Network status changed: connected=$isConnected")
                if (isConnected) {
                    Timber.tag("PLAYLIST").d("Network connected, reconnecting WebSocket and syncing playlists")
                    webSocketManager.connect()
                    syncPlaylists()
                }
            }
        }
    }

    fun loadCurrentPlaylist() {
        viewModelScope.launch {
            try {
                Timber.tag("PLAYLIST").d("Loading current playlist")
                val playlists = playlistRepository.getPlaylists()
                val current = playlists.firstOrNull { it.isActive } ?: playlists.firstOrNull()
                Timber.tag("PLAYLIST").d("CURRENT: ${current?.name}")

                if (current != null) {
                    Timber.tag("PLAYLIST").d("Loaded playlist: ${current.name} (id=${current.id})")
                    _currentPlaylist.value = playlists.firstOrNull()
                } else {
                    Timber.tag("PLAYLIST").w("No playlists available")
                }
            } catch (e: Exception) {
                Timber.tag("PLAYLIST").e(e, "Failed to load current playlist")
            }
        }
    }

    private suspend fun handleWebSocketCommand(command: WebSocketCommand) {
        try {
            when (command) {
                is WebSocketCommand.Play -> {
                    Timber.tag("PLAYLIST").d("Handling Play command")
                    _playerCommand.emit(PlayerCommand.Play)
                }
                is WebSocketCommand.Pause -> {
                    Timber.tag("PLAYLIST").d("Handling Pause command")
                    _playerCommand.emit(PlayerCommand.Pause)
                }
                is WebSocketCommand.Next -> {
                    Timber.tag("PLAYLIST").d("Handling Next command")
                    _playerCommand.emit(PlayerCommand.Next)
                }
                is WebSocketCommand.Previous -> {
                    Timber.tag("PLAYLIST").d("Handling Previous command")
                    _playerCommand.emit(PlayerCommand.Previous)
                }
                is WebSocketCommand.ReloadPlaylist -> {
                    Timber.tag("PLAYLIST").d("Handling ReloadPlaylist command")
                    reloadPlaylist()
                }
                is WebSocketCommand.SwitchPlaylist -> {
                    Timber.tag("PLAYLIST").d("Handling SwitchPlaylist command: playlistId=${command.playlistId}")
                    switchPlaylist(command.playlistId)
                }
                is WebSocketCommand.PlayMedia -> {
                    Timber.tag("PLAYLIST").d("Handling PlayMedia command: mediaId=${command.mediaId}, mediaIndex=${command.mediaIndex}")
                    _playerCommand.emit(
                        PlayerCommand.PlaySpecificMedia(command.mediaId, command.mediaIndex)
                    )
                }
                is WebSocketCommand.ShowTextOverlay -> {
                    Timber.tag("PLAYLIST").d("Handling ShowTextOverlay command: text=${command.textOverlay.text}")
                    _playerCommand.emit(PlayerCommand.ShowTextOverlay(command.textOverlay))
                }
                is WebSocketCommand.HideTextOverlay -> {
                    Timber.tag("PLAYLIST").d("Handling HideTextOverlay command")
                    _playerCommand.emit(PlayerCommand.HideTextOverlay)
                }
                is WebSocketCommand.SetBrightness -> {
                    Timber.tag("PLAYLIST").d("Handling SetBrightness command: brightness=${command.brightness}")
                    _playerCommand.emit(PlayerCommand.SetBrightness(command.brightness))
                }
                is WebSocketCommand.SetVolume -> {
                    Timber.tag("PLAYLIST").d("Handling SetVolume command: volume=${command.volume}")
                    _playerCommand.emit(PlayerCommand.SetVolume(command.volume))
                }
                is WebSocketCommand.CleanupOldPlaylists -> {
                    Timber.tag("PLAYLIST").d("Handling CleanupOldPlaylists command: keep=${command.playlistIdsToKeep}")
                    cleanupOldPlaylists(command.playlistIdsToKeep)
                }
            }
        } catch (e: Exception) {
            Timber.tag("PLAYLIST").e(e, "Error handling WebSocket command: $command")
        }
    }

    private suspend fun reloadPlaylist() {
        val currentPlaylist = _currentPlaylist.value
        if (currentPlaylist == null) {
            Timber.tag("PLAYLIST").w("Cannot reload playlist: no current playlist")
            return
        }

        try {
//            Timber.tag("PLAYLIST").d("Reloading playlist: ${currentPlaylist()}")
//            playlistRepository.downloadPlaylist(currentPlaylist.id)
            loadCurrentPlaylist()
            _playerCommand.emit(PlayerCommand.ReloadCurrentPlaylist)
        } catch (e: Exception) {
            Timber.tag("PLAYLIST").e(e, "Failed to reload playlist")
        }
    }

    private suspend fun switchPlaylist(playlistId: Int) {
        try {
            Timber.tag("PLAYLIST").d("Switching to playlist: $playlistId")
            val playlist = playlistRepository.getPlaylist(playlistId)

            if (playlist.downloadStatus != DownloadStatus.READY) {
                Timber.tag("PLAYLIST").d("Playlist not ready, downloading: $playlistId")
                playlistRepository.downloadPlaylist(playlistId)
            }

            _currentPlaylist.value = playlist
//            _playerCommand.emit(PlayerCommand.SwitchPlaylist(playlist))
        } catch (e: Exception) {
            Timber.tag("PLAYLIST").e(e, "Failed to switch playlist: $playlistId")
        }
    }

    private suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>) {
        try {
            Timber.tag("PLAYLIST").d("Cleaning up old playlists, keeping: $playlistIdsToKeep")
            playlistRepository.cleanupOldPlaylists(playlistIdsToKeep)
        } catch (e: Exception) {
            Timber.tag("PLAYLIST").e(e, "Failed to cleanup old playlists")
        }
    }

    private suspend fun syncPlaylists() {
        try {
            Timber.tag("PLAYLIST").d("Syncing playlists from server")
            playlistRepository.syncPlaylists()
        } catch (e: Exception) {
            Timber.tag("PLAYLIST").e(e, "Failed to sync playlists")
        }
    }

    override fun onCleared() {
        super.onCleared()
        Timber.tag("PLAYLIST").d("PlayerViewModel cleared")
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
