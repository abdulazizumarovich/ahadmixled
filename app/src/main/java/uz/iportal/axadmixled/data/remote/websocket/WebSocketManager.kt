package uz.iportal.axadmixled.data.remote.websocket

import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
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
import uz.iportal.axadmixled.domain.model.PlaylistStatusMessage
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
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

@Singleton
class WebSocketManager @Inject constructor(
    private val authPreferences: AuthPreferences,
    private val deviceRepository: DeviceRepository,
    private val storageMonitor: StorageMonitor,
    private val gson: Gson,
//    private val okHttpClient: OkHttpClient
) {
    private var webSocket: WebSocket? = null
    private var isConnected = false
    private var isReconnecting = false  // Track if reconnect is already scheduled
    private val _commands = MutableSharedFlow<WebSocketCommand>()
    private var storageMonitorJob: Job? = null
    private var reconnectJob: Job? = null
//    private val client = OkHttpClient.Builder()
//        .connectTimeout(10, TimeUnit.SECONDS)
//        .readTimeout(30, TimeUnit.SECONDS)
//        .writeTimeout(30, TimeUnit.SECONDS)
//        .build()
    val commands: SharedFlow<WebSocketCommand> = _commands.asSharedFlow()

    fun getUnsafeOkHttp(): OkHttpClient {
        val trustAllCerts = arrayOf<TrustManager>(
            object : X509TrustManager {
                override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {}
                override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {}
                override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
            }
        )

        val sslContext = SSLContext.getInstance("SSL")
        sslContext.init(null, trustAllCerts, SecureRandom())

        val sslSocketFactory = sslContext.socketFactory

        return OkHttpClient.Builder()
            .sslSocketFactory(sslSocketFactory, trustAllCerts[0] as X509TrustManager)
            .hostnameVerifier { _, _ -> true }
            .build()
    }


    fun connect() {
        // Prevent multiple simultaneous connection attempts
        if (isConnected || isReconnecting) {
            Timber.tag("WSLOG").d("Already connected or reconnecting, skipping connect()")
            return
        }

        val token = authPreferences.getAccessToken() ?: run {
            Timber.tag("WSLOG").e("No access token available")
            return
        }
        val snNumber = authPreferences.getDeviceSnNumber() ?: run {
            Timber.tag("WSLOG").e("No device SN number available")
            return
        }

        val url = ApiConstants.wsUrl(snNumber, token)
        Timber.tag("WSLOG").d("Connecting to WebSocket: $url")
        val request = Request.Builder().url(url).build()

//        webSocket?.close(1000, "Reconnecting")

        webSocket = getUnsafeOkHttp().newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                isConnected = true
                isReconnecting = false  // Reset reconnecting flag
                reconnectJob?.cancel()  // Cancel any pending reconnect attempts
                Timber.tag("WSLOG").d("WebSocket connected successfully")

                CoroutineScope(Dispatchers.IO).launch {
                    sendReadyPlaylists()
                    startStorageMonitoring()
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                if (text.contains("connection_established")) {
                    Timber.tag("WSLOG").d("Connection established message ignored")
                    return
                }

                Timber.tag("WSLOG").d("Message received: $text")
                handleIncomingMessage(text)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Timber.tag("WSLOG").e(t, "WebSocket failure: ${t.message}")
                handleDisconnect(reason = "Failure: ${t.message}")
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                Timber.tag("WSLOG").d("WebSocket closing: $code - $reason")
                handleDisconnect(reason = "Closing: $reason")
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Timber.tag("WSLOG").d("WebSocket closed: $code - $reason")
                handleDisconnect(reason = "Closed: $reason")
            }
        })
    }

    private fun handleDisconnect(reason: String) {
        // Prevent multiple reconnect attempts from running simultaneously
        if (isReconnecting) {
            Timber.tag("WSLOG").d("Reconnect already scheduled, ignoring duplicate disconnect: $reason")
            return
        }

        isConnected = false
        isReconnecting = true
        Timber.tag("WSLOG").w("WebSocket disconnected: $reason. Starting reconnect...")

        scheduleReconnect()
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
                    Timber.tag("WSLOG").w("Unknown command: ${commandDto.action}")
                    return
                }
            }

            CoroutineScope(Dispatchers.Main).launch {
                _commands.emit(command)
            }
        } catch (e: Exception) {
            Timber.tag("WSLOG").e(e, "Failed to parse WebSocket message")
        }
    }

    suspend fun sendReadyPlaylists() {
        if (!isConnected) return

        val readyPlaylistIds = deviceRepository.getReadyPlaylistIds()
        if (readyPlaylistIds.isNotEmpty()) {
            val message = ReadyPlaylistsMessage(
                playlist_ids = readyPlaylistIds
            )

            val json = gson.toJson(message)
            webSocket?.send(json)
            Timber.tag("WSLOG").d("Sent ready playlists: $json")
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
            Timber.tag("WSLOG").d("Sent storage update: $json")
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
                Timber.tag("WSLOG").d("Reconnecting WebSocket, attempt ${attempt + 1}/${Constants.WS_MAX_RETRY_ATTEMPTS}")
                connect()
                attempt++
                retryDelay = (retryDelay * 2).coerceAtMost(Constants.WS_MAX_RETRY_DELAY)
            }

            if (!isConnected) {
                Timber.tag("WSLOG")
                    .e("Failed to reconnect WebSocket after ${Constants.WS_MAX_RETRY_ATTEMPTS} attempts")
            }
            isReconnecting = false  // Reset flag after reconnect loop finishes
        }
    }

    fun disconnect() {
        isReconnecting = false
        storageMonitorJob?.cancel()
        reconnectJob?.cancel()
        webSocket?.close(1000, "Client disconnect")
        webSocket = null
        isConnected = false
    }

    fun isConnected(): Boolean = isConnected
}