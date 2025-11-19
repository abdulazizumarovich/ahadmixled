package uz.iportal.axadmixled.data.remote.websocket

import com.google.gson.Gson
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import okhttp3.*
import timber.log.Timber
import uz.iportal.axadmixled.core.constants.ApiConstants
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.domain.model.*
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import uz.iportal.axadmixled.util.Constants
import uz.iportal.axadmixled.util.StorageMonitor
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WebSocketManager @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val authPreferences: AuthPreferences,
    private val deviceRepository: DeviceRepository,
    private val storageMonitor: StorageMonitor,
    private val gson: Gson
) {
    private var webSocket: WebSocket? = null
    private var isConnected = false
    private val _commands = MutableSharedFlow<WebSocketCommand>()
    private var storageMonitorJob: Job? = null
    private var reconnectJob: Job? = null

    val commands: SharedFlow<WebSocketCommand> = _commands.asSharedFlow()

    suspend fun connect() {
        val token = authPreferences.getAccessToken() ?: run {
            Timber.e("No access token available")
            return
        }
        val snNumber = authPreferences.getDeviceSnNumber() ?: run {
            Timber.e("No device SN number available")
            return
        }

        val url = ApiConstants.wsUrl(snNumber, token)
        Timber.d("Connecting to WebSocket: $url")
        val request = Request.Builder().url(url).build()

        webSocket?.close(1000, "Reconnecting")
        webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                isConnected = true
                Timber.d("WebSocket connected")

                CoroutineScope(Dispatchers.IO).launch {
                    sendReadyPlaylists()
                    startStorageMonitoring()
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                Timber.d("WebSocket message received: $text")
                handleIncomingMessage(text)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                isConnected = false
                Timber.e(t, "WebSocket connection failed")
                scheduleReconnect()
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                isConnected = false
                Timber.d("WebSocket closing: $code - $reason")
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                isConnected = false
                Timber.d("WebSocket closed: $code - $reason")
                scheduleReconnect()
            }
        })
    }

    private fun handleIncomingMessage(message: String) {
        try {
            val commandDto = gson.fromJson(message, WebSocketCommandDto::class.java)
            val command = when (commandDto.action) {
                "play" -> WebSocketCommand.Play
                "pause" -> WebSocketCommand.Pause
                "next" -> WebSocketCommand.Next
                "previous" -> WebSocketCommand.Previous
                "reload_playlist" -> WebSocketCommand.ReloadPlaylist
                "switch_playlist" -> WebSocketCommand.SwitchPlaylist(
                    commandDto.playlistId ?: return
                )
                "play_media" -> WebSocketCommand.PlayMedia(
                    commandDto.mediaId,
                    commandDto.mediaIndex
                )
                "show_text_overlay" -> {
                    val overlayDto = commandDto.textOverlay ?: return
                    WebSocketCommand.ShowTextOverlay(
                        TextOverlay(
                            text = overlayDto.text,
                            position = TextPosition.fromString(overlayDto.position ?: "bottom"),
                            animation = TextAnimation.fromString(overlayDto.animation ?: "scroll"),
                            speed = overlayDto.speed ?: 50f,
                            fontSize = overlayDto.font_size ?: 24,
                            backgroundColor = overlayDto.background_color ?: "#000000",
                            textColor = overlayDto.text_color ?: "#FFFFFF"
                        )
                    )
                }
                "hide_text_overlay" -> WebSocketCommand.HideTextOverlay
                "set_brightness" -> WebSocketCommand.SetBrightness(
                    commandDto.brightness ?: 100
                )
                "set_volume" -> WebSocketCommand.SetVolume(
                    commandDto.volume ?: 100
                )
                "cleanup_old_playlists" -> WebSocketCommand.CleanupOldPlaylists(
                    commandDto.playlistIdsToKeep ?: emptyList()
                )
                else -> {
                    Timber.w("Unknown command: ${commandDto.action}")
                    return
                }
            }

            CoroutineScope(Dispatchers.Main).launch {
                _commands.emit(command)
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to parse WebSocket message")
        }
    }

    fun sendPlaylistStatus(
        playlistId: Int,
        status: String,
        totalItems: Int,
        downloadedItems: Int,
        missingFiles: List<String>? = null,
        error: String? = null
    ) {
        if (!isConnected) {
            Timber.w("WebSocket not connected, cannot send playlist status")
            return
        }

        val message = PlaylistStatusMessage(
            playlist_id = playlistId,
            status = status,
            total_items = totalItems,
            downloaded_items = downloadedItems,
            missing_files = missingFiles,
            error = error
        )

        val json = gson.toJson(message)
        webSocket?.send(json)
        Timber.d("Sent playlist status: $json")
    }

    suspend fun sendReadyPlaylists() {
        if (!isConnected) return

        val readyPlaylistIds = deviceRepository.getReadyPlaylistIds()

        val message = ReadyPlaylistsMessage(
            playlist_ids = readyPlaylistIds
        )

        val json = gson.toJson(message)
        webSocket?.send(json)
        Timber.d("Sent ready playlists: $json")
    }

    private fun startStorageMonitoring() {
        storageMonitorJob?.cancel()
        storageMonitorJob = CoroutineScope(Dispatchers.IO).launch {
            storageMonitor.storageUpdates.collect { storageInfo ->
                sendStorageUpdate(storageInfo)
            }
        }
    }

    private fun sendStorageUpdate(storageInfo: StorageInfo) {
        if (!isConnected) return

        CoroutineScope(Dispatchers.IO).launch {
            val snNumber = authPreferences.getDeviceSnNumber() ?: return@launch

            val message = DeviceStorageUpdate(
                snNumber = snNumber,
                storageTotal = storageInfo.totalSpace,
                storageFree = storageInfo.freeSpace,
                storageUsed = storageInfo.usedSpace
            )

            val json = gson.toJson(message)
            webSocket?.send(json)
            Timber.d("Sent storage update: $json")
        }
    }

    fun sendDeviceStatus(
        currentPlaylistId: Int?,
        currentMediaId: Int?,
        playbackState: String
    ) {
        if (!isConnected) return

        CoroutineScope(Dispatchers.IO).launch {
            val snNumber = authPreferences.getDeviceSnNumber() ?: return@launch

            val message = DeviceStatusMessage(
                sn_number = snNumber,
                is_online = true,
                current_playlist_id = currentPlaylistId,
                current_media_id = currentMediaId,
                playback_state = playbackState
            )

            val json = gson.toJson(message)
            webSocket?.send(json)
        }
    }

    private fun scheduleReconnect() {
        reconnectJob?.cancel()
        reconnectJob = CoroutineScope(Dispatchers.IO).launch {
            var retryDelay = Constants.WS_INITIAL_RETRY_DELAY
            var attempt = 0

            while (!isConnected && attempt < Constants.WS_MAX_RETRY_ATTEMPTS) {
                delay(retryDelay)
                Timber.d("Reconnecting WebSocket, attempt ${attempt + 1}/${Constants.WS_MAX_RETRY_ATTEMPTS}")
                connect()
                attempt++
                retryDelay = (retryDelay * 2).coerceAtMost(Constants.WS_MAX_RETRY_DELAY)
            }

            if (!isConnected) {
                Timber.e("Failed to reconnect WebSocket after ${Constants.WS_MAX_RETRY_ATTEMPTS} attempts")
            }
        }
    }

    fun disconnect() {
        storageMonitorJob?.cancel()
        reconnectJob?.cancel()
        webSocket?.close(1000, "Client disconnect")
        webSocket = null
        isConnected = false
    }

    fun isConnected(): Boolean = isConnected
}
