package uz.iportal.axadmixled.presentation.splash

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.data.remote.websocket.WebSocketManager
import uz.iportal.axadmixled.domain.model.DownloadStatus
import uz.iportal.axadmixled.domain.repository.AuthRepository
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import javax.inject.Inject

@HiltViewModel
class SplashViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val deviceRepository: DeviceRepository,
    private val playlistRepository: PlaylistRepository,
    private val webSocketManager: WebSocketManager
) : ViewModel() {

    fun initializeApp(): Flow<AppState> = flow {
        try {
            Timber.d("Starting app initialization")

            // Check authentication
            if (!authRepository.isAuthenticated()) {
                Timber.d("User not authenticated, navigating to login")
                emit(AppState.NeedsAuth)
                return@flow
            }

            // Refresh token if needed
            Timber.d("Checking token validity")
            authRepository.refreshTokenIfNeeded()

            // Check device registration
            if (!deviceRepository.isDeviceRegistered()) {
                Timber.d("Device not registered, registering now")
                deviceRepository.registerDevice()
            }

            // Connect WebSocket
            Timber.d("Connecting to WebSocket")
            webSocketManager.connect()

            // Load playlists
            Timber.d("Loading playlists from database")
            val playlists = playlistRepository.getPlaylists()
            // Start background download for remaining playlists
            viewModelScope.launch {
                Timber.d("Starting background downloads for remaining playlists")
                playlistRepository.downloadRemainingPlaylistsInBackground()
            }
            // Download current playlist if needed
            val currentPlaylist = playlists.firstOrNull { it.isActive } ?: playlists.firstOrNull()

            if (currentPlaylist == null) {
                Timber.e("No playlists available")
                emit(AppState.Error("No playlists available"))
                return@flow
            }

//            if (currentPlaylist.downloadStatus != DownloadStatus.READY) {
//                Timber.d("Downloading current playlist: ${currentPlaylist.id}")
//                playlistRepository.downloadPlaylist(currentPlaylist.id)
//            }

            // Start background download for remaining playlists
//            viewModelScope.launch {
//                Timber.d("Starting background downloads for remaining playlists")
//                playlistRepository.downloadRemainingPlaylistsInBackground()
//            }

            Timber.d("App initialization complete")
            emit(AppState.Ready)
        } catch (e: Exception) {
            Timber.e(e, "App initialization failed")
            emit(AppState.Error(e.message ?: "Unknown error"))
        }
    }
}

sealed class AppState {
    object NeedsAuth : AppState()
    object Ready : AppState()
    data class Error(val message: String) : AppState()
}
