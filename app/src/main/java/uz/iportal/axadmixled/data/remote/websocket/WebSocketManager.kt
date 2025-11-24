package uz.iportal.axadmixled.data.remote.websocket

import com.google.gson.Gson
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import timber.log.Timber
import uz.iportal.axadmixled.core.constants.ApiConstants
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.domain.model.DeviceStatusMessage
import uz.iportal.axadmixled.domain.model.DeviceStorageUpdate
import uz.iportal.axadmixled.domain.model.ReadyPlaylistsMessage
import uz.iportal.axadmixled.domain.model.StorageInfo
import uz.iportal.axadmixled.domain.model.TextAnimation
import uz.iportal.axadmixled.domain.model.TextOverlay
import uz.iportal.axadmixled.domain.model.TextPosition
import uz.iportal.axadmixled.domain.model.WebSocketCommand
import uz.iportal.axadmixled.domain.model.WebSocketCommandDto
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import uz.iportal.axadmixled.util.Constants
import uz.iportal.axadmixled.util.StorageMonitor
import uz.iportal.axadmixled.util.getInt
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "WebSocketManager"

@Singleton
class WebSocketManager @Inject constructor(
    private val authPreferences: AuthPreferences,
    private val deviceRepository: DeviceRepository,
    private val storageMonitor: StorageMonitor,
    private val okHttpClient: OkHttpClient,
    private val gson: Gson
) {
    private var webSocket: WebSocket? = null
    private var isConnected = false
    private var isConnecting = false  // Track if reconnect is already scheduled
    private val _commands = MutableSharedFlow<WebSocketCommand>(
        replay = 1,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    private var storageMonitorJob: Job? = null
    private var reconnectJob: Job? = null
    val commands: SharedFlow<WebSocketCommand> = _commands.asSharedFlow()

    private val sendingMessageQueue = mutableMapOf<String, String>()

    fun connect() {
        // Prevent multiple simultaneous connection attempts
        if (isConnected || isConnecting) {
            Timber.tag(TAG).d("Already connected or connecting, skipping connect()")
            return
        }

        val token = authPreferences.getAccessToken() ?: run {
            Timber.tag(TAG).e("No access token available")
            return
        }
        val snNumber = authPreferences.getDeviceSnNumber() ?: run {
            Timber.tag(TAG).e("No device SN number available")
            return
        }

        val url = ApiConstants.wsUrl(authPreferences.getIp(), snNumber, token)
        Timber.tag(TAG).d("Connecting to WebSocket: $url")
        val request = Request.Builder().url(url).build()

        isConnecting = true
        webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                isConnected = true
                isConnecting = false  // Reset reconnecting flag
                Timber.tag(TAG).d("WebSocket connected successfully")
                attempt = 0
                retryDelay = Constants.WS_INITIAL_RETRY_DELAY

                CoroutineScope(Dispatchers.IO).launch {
                    sendReadyPlaylists()
                    startStorageMonitoring()
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                if (text.contains("connection_established")) {
                    Timber.tag(TAG).d("Connection established message ignored")
                    return
                }

                Timber.tag(TAG).d("Message received: $text")
                handleIncomingMessage(text)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Timber.tag(TAG).e(t, "WebSocket failure: ${t.message}")
                handleDisconnect(reason = "Failure: ${t.message}")
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                Timber.tag(TAG).d("WebSocket closing: $code - $reason")
                handleDisconnect(reason = "Closing: $reason")
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Timber.tag(TAG).d("WebSocket closed: $code - $reason")
                handleDisconnect(reason = "Closed: $reason")
            }
        })
    }

    private fun handleDisconnect(reason: String) {
        isConnected = false
        isConnecting = false
        Timber.tag(TAG).w("WebSocket disconnected: $reason. Starting reconnect...")
        scheduleReconnect()
    }

    private fun handleIncomingMessage(message: String) {
        try {
            val commandDto = gson.fromJson(message, WebSocketCommandDto::class.java)
            Timber.tag(TAG).d("Serialized as: $commandDto")
            val command = when (commandDto.action) {
                "play" -> WebSocketCommand.Play
                "pause" -> WebSocketCommand.Pause
                "next" -> WebSocketCommand.Next
                "previous" -> WebSocketCommand.Previous
                "reload_playlist" -> WebSocketCommand.ReloadPlaylist(
                    newPlaylist = commandDto.parameters.getInt("new_solution_id")
                )
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
                    Timber.tag(TAG).w("Unknown command: ${commandDto.action}")
                    return
                }
            }

            Timber.tag(TAG).d("Emitting command $command")
            val send = _commands.tryEmit(command)
            if (!send) Timber.tag(TAG).e("Failed to emit command $command")
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to parse WebSocket message")
        }
    }

    suspend fun sendReadyPlaylists() {
        val readyPlaylistIds = deviceRepository.getReadyPlaylistIds()
        if (readyPlaylistIds.isNotEmpty()) {
            val message = ReadyPlaylistsMessage(
                playlist_ids = readyPlaylistIds
            )

            val json = gson.toJson(message)
            send(message.type, json)
        }
    }

    /**
     * Send a message to the WebSocket.
     * If the WebSocket is not connected, add the message to the queue.
     * If the WebSocket is already connected, send the message immediately and other pending ones too.
     *
     * @param type The type of the message.
     * @param json The JSON representation of the message.
     */
    private fun send(type: String, json: String) {
        sendingMessageQueue[type] = json
        if (!isConnected) return

        val iterator = sendingMessageQueue.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()

            if (webSocket?.send(entry.value) == false) break

            Timber.tag(TAG).d("Sent: $json")
            iterator.remove()
        }
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
        CoroutineScope(Dispatchers.IO).launch {
            val snNumber = authPreferences.getDeviceSnNumber() ?: return@launch

            val message = DeviceStorageUpdate(
                snNumber = snNumber,
                storageTotal = storageInfo.totalSpace,
                storageFree = storageInfo.freeSpace,
                storageUsed = storageInfo.usedSpace
            )

            val json = gson.toJson(message)
            send(message.type, json)
        }
    }

    fun sendDeviceStatus(
        currentPlaylistId: Int?,
        currentMediaId: Int?,
        playbackState: String
    ) {
        if (!isConnected) return

        /*CoroutineScope(Dispatchers.IO).launch {
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
            Timber.tag(TAG).d("Sent device status: $json")
        }*/
    }

    var retryDelay = Constants.WS_INITIAL_RETRY_DELAY
    var attempt = 0

    private fun scheduleReconnect() {
        reconnectJob?.cancel()

        if (attempt >= Constants.WS_MAX_RETRY_ATTEMPTS) {
            Timber.tag(TAG)
                .e("Failed to reconnect WebSocket after ${Constants.WS_MAX_RETRY_ATTEMPTS} attempts")
            isConnecting = false  // Reset flag after reconnect loop finishes
            return
        }

        reconnectJob = CoroutineScope(Dispatchers.IO).launch {
            try {
                delay(retryDelay)
            } catch (_: CancellationException) {
                Timber.tag(TAG).e("Reconnect scheduled did not fire, coroutine cancelled")
                attempt = 0
                retryDelay = Constants.WS_INITIAL_RETRY_DELAY
                return@launch
            }

            retryDelay = (retryDelay * 2).coerceAtMost(Constants.WS_MAX_RETRY_DELAY)
            Timber.tag(TAG).d("Reconnecting WebSocket, attempt ${attempt + 1}/${Constants.WS_MAX_RETRY_ATTEMPTS}")
            connect()
            attempt++
        }
    }

    fun disconnect() {
        isConnecting = false
        storageMonitorJob?.cancel()
        reconnectJob?.cancel()
        webSocket?.close(1000, "Client disconnect")
        webSocket = null
        isConnected = false
    }

    fun isConnected(): Boolean = isConnected
}