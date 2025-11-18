# Android LED Player - Complete Technical Specification

## 📋 Project Overview

**Project Name:** Android LED Player  
**Platform:** Android Native (Kotlin)  
**Minimum SDK:** 21 (Android 5.0)  
**Target SDK:** 34+  
**Architecture:** Clean Architecture  
**Principles:** SOLID, DRY, KISS  

### Purpose
Native Android application for LED screens to display advertisements (video and images) with remote control capabilities via WebSocket. The app must work autonomously with offline-first architecture.

### Key Requirements
- **Offline-First**: Must work indefinitely without internet after initial setup
- **Autonomous**: Auto-reconnect, auto-refresh tokens, self-healing
- **Fast**: Instant playback from local storage, no loading screens
- **Silent**: No error dialogs, only logging
- **Real-time Sync**: Storage info, playlist status, device status via WebSocket

---

## 🏗️ Project Structure

```
app/
├── data/
│   ├── local/
│   │   ├── database/
│   │   │   ├── AppDatabase.kt
│   │   │   ├── dao/
│   │   │   │   ├── PlaylistDao.kt
│   │   │   │   ├── MediaDao.kt
│   │   │   │   └── DeviceDao.kt
│   │   │   └── entities/
│   │   │       ├── PlaylistEntity.kt
│   │   │       ├── MediaEntity.kt
│   │   │       └── DeviceEntity.kt
│   │   ├── preferences/
│   │   │   └── AuthPreferences.kt
│   │   └── storage/
│   │       └── MediaFileManager.kt
│   ├── remote/
│   │   ├── api/
│   │   │   ├── AuthApi.kt
│   │   │   ├── DeviceApi.kt
│   │   │   ├── PlaylistApi.kt
│   │   │   └── ScreenshotApi.kt
│   │   ├── websocket/
│   │   │   ├── WebSocketManager.kt
│   │   │   └── WebSocketMessageHandler.kt
│   │   └── dto/
│   │       ├── AuthDto.kt
│   │       ├── PlaylistDto.kt
│   │       ├── MediaDto.kt
│   │       └── WebSocketDto.kt
│   └── repository/
│       ├── AuthRepositoryImpl.kt
│       ├── DeviceRepositoryImpl.kt
│       ├── PlaylistRepositoryImpl.kt
│       ├── MediaRepositoryImpl.kt
│       └── ScreenshotRepositoryImpl.kt
├── domain/
│   ├── model/
│   │   ├── Auth.kt
│   │   ├── Device.kt
│   │   ├── Playlist.kt
│   │   ├── Media.kt
│   │   ├── WebSocketCommand.kt
│   │   └── WebSocketStatus.kt
│   ├── repository/
│   │   ├── AuthRepository.kt
│   │   ├── DeviceRepository.kt
│   │   ├── PlaylistRepository.kt
│   │   ├── MediaRepository.kt
│   │   └── ScreenshotRepository.kt
│   └── usecase/
│       ├── auth/
│       │   ├── LoginUseCase.kt
│       │   ├── RefreshTokenUseCase.kt
│       │   └── AutoRefreshTokenUseCase.kt
│       ├── device/
│       │   ├── RegisterDeviceUseCase.kt
│       │   ├── GetDeviceInfoUseCase.kt
│       │   └── UpdateStorageInfoUseCase.kt
│       ├── playlist/
│       │   ├── GetPlaylistsUseCase.kt
│       │   ├── DownloadPlaylistUseCase.kt
│       │   ├── SyncPlaylistsUseCase.kt
│       │   └── CleanupOldPlaylistsUseCase.kt
│       ├── media/
│       │   ├── DownloadMediaUseCase.kt
│       │   ├── GetLocalMediaUseCase.kt
│       │   └── VerifyMediaChecksumUseCase.kt
│       └── websocket/
│           ├── ConnectWebSocketUseCase.kt
│           ├── SendPlaylistStatusUseCase.kt
│           ├── SendDeviceStatusUseCase.kt
│           └── HandleWebSocketCommandUseCase.kt
├── presentation/
│   ├── splash/
│   │   ├── SplashActivity.kt
│   │   └── SplashViewModel.kt
│   ├── auth/
│   │   ├── AuthActivity.kt
│   │   └── AuthViewModel.kt
│   ├── player/
│   │   ├── PlayerActivity.kt
│   │   ├── PlayerViewModel.kt
│   │   └── components/
│   │       ├── MediaPlayerManager.kt
│   │       ├── VideoPlayerView.kt
│   │       ├── ImagePlayerView.kt
│   │       └── TextOverlayView.kt
│   └── base/
│       └── BaseViewModel.kt
├── di/
│   ├── AppModule.kt
│   ├── NetworkModule.kt
│   ├── DatabaseModule.kt
│   ├── RepositoryModule.kt
│   └── UseCaseModule.kt
└── util/
    ├── Constants.kt
    ├── NetworkMonitor.kt
    ├── StorageMonitor.kt
    ├── ScreenshotCapture.kt
    └── Extensions.kt
```

---

## 🌐 API Endpoints

### Base URL
```
https://admin-led.ohayo.uz
```

### Authentication
- **Login:** `POST /api/v1/auth/token/`
- **Refresh Token:** `POST /api/v1/auth/token/refresh/`

### Device Management
- **Register Device:** `POST /api/v1/admin/cloud/device/register/`
- **Get Device Info:** `GET /api/v1/admin/cloud/device/{sn_number}/`

### Playlist Management
- **Get Playlists:** `GET /api/v1/admin/cloud/playlists?sn_number={sn_number}`
- **Get Playlist Detail:** `GET /api/v1/admin/cloud/playlists/{id}/`

### Screenshot Upload
- **Upload Screenshot:** `POST /api/v1/admin/cloud/screenshots/` (Ready for backend implementation)

### WebSocket Connection
```
wss://admin-led.ohayo.uz/ws/cloud/tb_device/?token={access_token}&sn_number={device_id}
```

---

## 📦 Domain Models

### 1. Authentication Models

```kotlin
// domain/model/Auth.kt
package com.ledplayer.domain.model

data class AuthTokens(
    val access: String,
    val refresh: String,
    val expiresAt: Long = System.currentTimeMillis() + (24 * 60 * 60 * 1000)
)

data class LoginRequest(
    val username: String,
    val password: String
)

data class LoginResponse(
    val access: String,
    val refresh: String
)

data class RefreshTokenRequest(
    val refresh: String
)

data class RefreshTokenResponse(
    val access: String,
    val refresh: String
)
```

### 2. Device Models

```kotlin
// domain/model/Device.kt
package com.ledplayer.domain.model

data class Device(
    val id: Int,
    val snNumber: String,
    val name: String,
    val model: String,
    val androidVersion: String,
    val screenResolution: String,
    val storageTotal: Long,
    val storageFree: Long,
    val storageUsed: Long,
    val lastOnline: String,
    val isActive: Boolean,
    val createdAt: String,
    val updatedAt: String
)

data class DeviceRegisterRequest(
    val snNumber: String,
    val name: String,
    val model: String,
    val osVersion: String,
    val screenResolution: String,
    val storageCapacity: Long
)

data class DeviceRegisterResponse(
    val id: Int,
    val snNumber: String,
    val name: String,
    val isActive: Boolean,
    val createdAt: String
)

data class DeviceStorageUpdate(
    val type: String = "device_storage",
    val snNumber: String,
    val storageTotal: Long,
    val storageFree: Long,
    val storageUsed: Long,
    val timestamp: Long = System.currentTimeMillis()
)
```

### 3. Playlist Models

```kotlin
// domain/model/Playlist.kt
package com.ledplayer.domain.model

data class Playlist(
    val id: Int,
    val name: String,
    val description: String?,
    val isActive: Boolean,
    val priority: Int,
    val duration: Int, // Total duration in seconds
    val mediaCount: Int,
    val createdAt: String,
    val updatedAt: String,
    val media: List<Media> = emptyList(),
    
    // Local fields
    val downloadStatus: DownloadStatus = DownloadStatus.PENDING,
    val downloadedItems: Int = 0,
    val missingFiles: List<String> = emptyList(),
    val lastSyncedAt: Long? = null
)

data class PlaylistResponse(
    val count: Int,
    val next: String?,
    val previous: String?,
    val results: List<PlaylistDetail>
)

data class PlaylistDetail(
    val id: Int,
    val name: String,
    val description: String?,
    val isActive: Boolean,
    val priority: Int,
    val duration: Int,
    val mediaCount: Int,
    val media: List<MediaDetail>,
    val createdAt: String,
    val updatedAt: String
)

enum class DownloadStatus {
    PENDING,
    DOWNLOADING,
    READY,
    PARTIAL,
    FAILED
}
```

### 4. Media Models

```kotlin
// domain/model/Media.kt
package com.ledplayer.domain.model

data class Media(
    val id: Int,
    val name: String,
    val description: String?,
    val file: String, // URL to media file
    val thumbnail: String?, // URL to thumbnail
    val mediaType: MediaType,
    val duration: Int, // Duration in seconds (for video) or display time (for image)
    val fileSize: Long,
    val resolution: String?, // e.g., "1920x1080"
    val checksum: String?,
    val order: Int, // Order in playlist
    val createdAt: String,
    val updatedAt: String,
    
    // Local fields
    val localPath: String? = null,
    val isDownloaded: Boolean = false,
    val downloadedAt: Long? = null,
    val downloadProgress: Int = 0
)

data class MediaDetail(
    val id: Int,
    val name: String,
    val description: String?,
    val file: String,
    val thumbnail: String?,
    val mediaType: String, // "video" or "image"
    val duration: Int,
    val fileSize: Long,
    val resolution: String?,
    val checksum: String?,
    val order: Int,
    val createdAt: String,
    val updatedAt: String
)

enum class MediaType {
    VIDEO,
    IMAGE;
    
    companion object {
        fun fromString(type: String): MediaType {
            return when (type.lowercase()) {
                "video" -> VIDEO
                "image" -> IMAGE
                else -> VIDEO
            }
        }
    }
}
```

### 5. WebSocket Command Models

```kotlin
// domain/model/WebSocketCommand.kt
package com.ledplayer.domain.model

sealed class WebSocketCommand {
    object Play : WebSocketCommand()
    object Pause : WebSocketCommand()
    object Next : WebSocketCommand()
    object Previous : WebSocketCommand()
    object ReloadPlaylist : WebSocketCommand()
    data class SwitchPlaylist(val playlistId: Int) : WebSocketCommand()
    data class PlayMedia(val mediaId: Int?, val mediaIndex: Int?) : WebSocketCommand()
    data class ShowTextOverlay(val textOverlay: TextOverlay) : WebSocketCommand()
    object HideTextOverlay : WebSocketCommand()
    data class SetBrightness(val brightness: Int) : WebSocketCommand()
    data class SetVolume(val volume: Int) : WebSocketCommand()
    data class CleanupOldPlaylists(val playlistIdsToKeep: List<Int>) : WebSocketCommand()
}

data class WebSocketCommandDto(
    val action: String,
    val playlistId: Int? = null,
    val mediaId: Int? = null,
    val mediaIndex: Int? = null,
    val textOverlay: TextOverlayDto? = null,
    val brightness: Int? = null,
    val volume: Int? = null,
    val playlistIdsToKeep: List<Int>? = null
)

data class TextOverlay(
    val text: String,
    val position: TextPosition = TextPosition.BOTTOM,
    val animation: TextAnimation = TextAnimation.SCROLL,
    val speed: Float = 50f,
    val fontSize: Int = 24,
    val backgroundColor: String = "#000000",
    val textColor: String = "#FFFFFF"
)

data class TextOverlayDto(
    val text: String,
    val position: String? = "bottom",
    val animation: String? = "scroll",
    val speed: Float? = 50f,
    val font_size: Int? = 24,
    val background_color: String? = "#000000",
    val text_color: String? = "#FFFFFF"
)

enum class TextPosition {
    TOP, BOTTOM, LEFT, RIGHT;
    
    companion object {
        fun fromString(position: String): TextPosition {
            return when (position.lowercase()) {
                "top" -> TOP
                "bottom" -> BOTTOM
                "left" -> LEFT
                "right" -> RIGHT
                else -> BOTTOM
            }
        }
    }
}

enum class TextAnimation {
    SCROLL, STATIC;
    
    companion object {
        fun fromString(animation: String): TextAnimation {
            return when (animation.lowercase()) {
                "scroll" -> SCROLL
                "static" -> STATIC
                else -> SCROLL
            }
        }
    }
}
```

### 6. WebSocket Status Models

```kotlin
// domain/model/WebSocketStatus.kt
package com.ledplayer.domain.model

data class PlaylistStatusMessage(
    val type: String = "playlist_status",
    val playlist_id: Int,
    val status: String, // "ready", "downloading", "partial", "failed"
    val total_items: Int,
    val downloaded_items: Int,
    val missing_files: List<String>? = null,
    val error: String? = null
)

data class ReadyPlaylistsMessage(
    val type: String = "ready_playlists",
    val playlist_ids: List<Int>
)

data class DeviceStatusMessage(
    val type: String = "device_status",
    val sn_number: String,
    val is_online: Boolean,
    val current_playlist_id: Int?,
    val current_media_id: Int?,
    val playback_state: String, // "playing", "paused", "stopped"
    val timestamp: Long = System.currentTimeMillis()
)

data class StorageInfo(
    val totalSpace: Long,
    val freeSpace: Long,
    val usedSpace: Long,
    val usedByApp: Long = 0L
) {
    val freeSpacePercentage: Float
        get() = (freeSpace.toFloat() / totalSpace.toFloat()) * 100
    
    val usedSpacePercentage: Float
        get() = (usedSpace.toFloat() / totalSpace.toFloat()) * 100
}
```

---

## 🗄️ Database Layer (Room)

### Entities

```kotlin
// data/local/database/entities/PlaylistEntity.kt
package com.ledplayer.data.local.database.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "playlists")
data class PlaylistEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val description: String?,
    @ColumnInfo(name = "is_active") val isActive: Boolean,
    val priority: Int,
    val duration: Int,
    @ColumnInfo(name = "media_count") val mediaCount: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
    @ColumnInfo(name = "download_status") val downloadStatus: String,
    @ColumnInfo(name = "downloaded_items") val downloadedItems: Int,
    @ColumnInfo(name = "missing_files") val missingFiles: String?, // JSON array
    @ColumnInfo(name = "last_synced_at") val lastSyncedAt: Long?
)

// data/local/database/entities/MediaEntity.kt
package com.ledplayer.data.local.database.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "media",
    foreignKeys = [
        ForeignKey(
            entity = PlaylistEntity::class,
            parentColumns = ["id"],
            childColumns = ["playlist_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("playlist_id"), Index("order")]
)
data class MediaEntity(
    @PrimaryKey val id: Int,
    @ColumnInfo(name = "playlist_id") val playlistId: Int,
    val name: String,
    val description: String?,
    val file: String, // Remote URL
    val thumbnail: String?,
    @ColumnInfo(name = "media_type") val mediaType: String,
    val duration: Int,
    @ColumnInfo(name = "file_size") val fileSize: Long,
    val resolution: String?,
    val checksum: String?,
    val order: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
    @ColumnInfo(name = "local_path") val localPath: String?,
    @ColumnInfo(name = "is_downloaded") val isDownloaded: Boolean,
    @ColumnInfo(name = "downloaded_at") val downloadedAt: Long?,
    @ColumnInfo(name = "download_progress") val downloadProgress: Int
)

// data/local/database/entities/DeviceEntity.kt
package com.ledplayer.data.local.database.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "device_info")
data class DeviceEntity(
    @PrimaryKey val id: Int,
    @ColumnInfo(name = "sn_number") val snNumber: String,
    val name: String,
    val model: String,
    @ColumnInfo(name = "android_version") val androidVersion: String,
    @ColumnInfo(name = "screen_resolution") val screenResolution: String,
    @ColumnInfo(name = "storage_total") val storageTotal: Long,
    @ColumnInfo(name = "storage_free") val storageFree: Long,
    @ColumnInfo(name = "storage_used") val storageUsed: Long,
    @ColumnInfo(name = "is_active") val isActive: Boolean,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "registered_at") val registeredAt: Long
)
```

### DAOs

```kotlin
// data/local/database/dao/PlaylistDao.kt
package com.ledplayer.data.local.database.dao

import androidx.room.*
import com.ledplayer.data.local.database.entities.PlaylistEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PlaylistDao {
    @Query("SELECT * FROM playlists ORDER BY priority DESC")
    fun getAllPlaylistsFlow(): Flow<List<PlaylistEntity>>
    
    @Query("SELECT * FROM playlists ORDER BY priority DESC")
    suspend fun getAllPlaylists(): List<PlaylistEntity>
    
    @Query("SELECT * FROM playlists WHERE id = :playlistId")
    suspend fun getPlaylistById(playlistId: Int): PlaylistEntity?
    
    @Query("SELECT * FROM playlists WHERE is_active = 1 LIMIT 1")
    suspend fun getActivePlaylist(): PlaylistEntity?
    
    @Query("SELECT id FROM playlists WHERE download_status = 'READY'")
    suspend fun getReadyPlaylistIds(): List<Int>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylist(playlist: PlaylistEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylists(playlists: List<PlaylistEntity>)
    
    @Update
    suspend fun updatePlaylist(playlist: PlaylistEntity)
    
    @Query("UPDATE playlists SET download_status = :status, downloaded_items = :downloadedItems WHERE id = :playlistId")
    suspend fun updateDownloadStatus(playlistId: Int, status: String, downloadedItems: Int)
    
    @Query("DELETE FROM playlists WHERE id = :playlistId")
    suspend fun deletePlaylist(playlistId: Int)
    
    @Query("DELETE FROM playlists WHERE id NOT IN (:playlistIds)")
    suspend fun deletePlaylistsNotIn(playlistIds: List<Int>)
}

// data/local/database/dao/MediaDao.kt
package com.ledplayer.data.local.database.dao

import androidx.room.*
import com.ledplayer.data.local.database.entities.MediaEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface MediaDao {
    @Query("SELECT * FROM media WHERE playlist_id = :playlistId ORDER BY `order` ASC")
    fun getMediaByPlaylistIdFlow(playlistId: Int): Flow<List<MediaEntity>>
    
    @Query("SELECT * FROM media WHERE playlist_id = :playlistId ORDER BY `order` ASC")
    suspend fun getMediaByPlaylistId(playlistId: Int): List<MediaEntity>
    
    @Query("SELECT * FROM media WHERE id = :mediaId")
    suspend fun getMediaById(mediaId: Int): MediaEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMedia(media: MediaEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMediaList(mediaList: List<MediaEntity>)
    
    @Update
    suspend fun updateMedia(media: MediaEntity)
    
    @Query("UPDATE media SET is_downloaded = 1, local_path = :localPath, downloaded_at = :downloadedAt WHERE id = :mediaId")
    suspend fun markAsDownloaded(mediaId: Int, localPath: String, downloadedAt: Long)
    
    @Query("DELETE FROM media WHERE playlist_id = :playlistId")
    suspend fun deleteMediaByPlaylistId(playlistId: Int)
}

// data/local/database/dao/DeviceDao.kt
package com.ledplayer.data.local.database.dao

import androidx.room.*
import com.ledplayer.data.local.database.entities.DeviceEntity

@Dao
interface DeviceDao {
    @Query("SELECT * FROM device_info LIMIT 1")
    suspend fun getDevice(): DeviceEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDevice(device: DeviceEntity)
    
    @Update
    suspend fun updateDevice(device: DeviceEntity)
    
    @Query("UPDATE device_info SET storage_total = :total, storage_free = :free, storage_used = :used")
    suspend fun updateStorage(total: Long, free: Long, used: Long)
}
```

### Database

```kotlin
// data/local/database/AppDatabase.kt
package com.ledplayer.data.local.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.ledplayer.data.local.database.dao.DeviceDao
import com.ledplayer.data.local.database.dao.MediaDao
import com.ledplayer.data.local.database.dao.PlaylistDao
import com.ledplayer.data.local.database.entities.DeviceEntity
import com.ledplayer.data.local.database.entities.MediaEntity
import com.ledplayer.data.local.database.entities.PlaylistEntity

@Database(
    entities = [
        PlaylistEntity::class,
        MediaEntity::class,
        DeviceEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun playlistDao(): PlaylistDao
    abstract fun mediaDao(): MediaDao
    abstract fun deviceDao(): DeviceDao
}
```

---

## 🌐 Network Layer

### Retrofit APIs

```kotlin
// data/remote/api/AuthApi.kt
package com.ledplayer.data.remote.api

import com.ledplayer.domain.model.LoginRequest
import com.ledplayer.domain.model.LoginResponse
import com.ledplayer.domain.model.RefreshTokenRequest
import com.ledplayer.domain.model.RefreshTokenResponse
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthApi {
    @POST("api/v1/auth/token/")
    suspend fun login(@Body request: LoginRequest): LoginResponse
    
    @POST("api/v1/auth/token/refresh/")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): RefreshTokenResponse
}

// data/remote/api/DeviceApi.kt
package com.ledplayer.data.remote.api

import com.ledplayer.domain.model.Device
import com.ledplayer.domain.model.DeviceRegisterRequest
import com.ledplayer.domain.model.DeviceRegisterResponse
import retrofit2.http.*

interface DeviceApi {
    @POST("api/v1/admin/cloud/device/register/")
    suspend fun registerDevice(
        @Header("Authorization") token: String,
        @Body request: DeviceRegisterRequest
    ): DeviceRegisterResponse
    
    @GET("api/v1/admin/cloud/device/{sn_number}/")
    suspend fun getDeviceInfo(
        @Header("Authorization") token: String,
        @Path("sn_number") snNumber: String
    ): Device
}

// data/remote/api/PlaylistApi.kt
package com.ledplayer.data.remote.api

import com.ledplayer.domain.model.PlaylistDetail
import com.ledplayer.domain.model.PlaylistResponse
import retrofit2.http.*

interface PlaylistApi {
    @GET("api/v1/admin/cloud/playlists")
    suspend fun getPlaylists(
        @Header("Authorization") token: String,
        @Query("sn_number") snNumber: String
    ): PlaylistResponse
    
    @GET("api/v1/admin/cloud/playlists/{id}/")
    suspend fun getPlaylistDetail(
        @Header("Authorization") token: String,
        @Path("id") playlistId: Int
    ): PlaylistDetail
}

// data/remote/api/ScreenshotApi.kt
package com.ledplayer.data.remote.api

import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.http.*

interface ScreenshotApi {
    @Multipart
    @POST("api/v1/admin/cloud/screenshots/")
    suspend fun uploadScreenshot(
        @Header("Authorization") token: String,
        @Part("sn_number") snNumber: RequestBody,
        @Part("media_id") mediaId: RequestBody,
        @Part("timestamp") timestamp: RequestBody,
        @Part screenshot: MultipartBody.Part
    ): ResponseBody
}
```

### WebSocket Manager

```kotlin
// data/remote/websocket/WebSocketManager.kt
package com.ledplayer.data.remote.websocket

import com.google.gson.Gson
import com.ledplayer.domain.model.*
import com.ledplayer.domain.repository.AuthRepository
import com.ledplayer.domain.repository.DeviceRepository
import com.ledplayer.util.StorageMonitor
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import okhttp3.*
import timber.log.Timber

class WebSocketManager(
    private val okHttpClient: OkHttpClient,
    private val authRepository: AuthRepository,
    private val deviceRepository: DeviceRepository,
    private val storageMonitor: StorageMonitor
) {
    private var webSocket: WebSocket? = null
    private var isConnected = false
    private val gson = Gson()
    private val messageHandler = MutableSharedFlow<WebSocketCommand>()
    private var storageMonitorJob: Job? = null
    
    val commands: SharedFlow<WebSocketCommand> = messageHandler.asSharedFlow()
    
    suspend fun connect() {
        val token = authRepository.getAccessToken() ?: run {
            Timber.e("No access token available")
            return
        }
        val snNumber = deviceRepository.getDeviceSnNumber() ?: run {
            Timber.e("No device SN number available")
            return
        }
        
        val url = "wss://admin-led.ohayo.uz/ws/cloud/tb_device/?token=$token&sn_number=$snNumber"
        val request = Request.Builder().url(url).build()
        
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
                messageHandler.emit(command)
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
            val snNumber = deviceRepository.getDeviceSnNumber() ?: return@launch
            
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
            val snNumber = deviceRepository.getDeviceSnNumber() ?: return@launch
            
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
        CoroutineScope(Dispatchers.IO).launch {
            var retryDelay = 1000L
            var attempt = 0
            val maxAttempts = 10
            
            while (!isConnected && attempt < maxAttempts) {
                delay(retryDelay)
                Timber.d("Reconnecting WebSocket, attempt ${attempt + 1}/$maxAttempts")
                connect()
                attempt++
                retryDelay = (retryDelay * 2).coerceAtMost(60000L)
            }
            
            if (!isConnected) {
                Timber.e("Failed to reconnect WebSocket after $maxAttempts attempts")
            }
        }
    }
    
    fun disconnect() {
        storageMonitorJob?.cancel()
        webSocket?.close(1000, "Client disconnect")
        webSocket = null
        isConnected = false
    }
}
```

---

## 💾 Storage & Utilities

### Storage Monitor

```kotlin
// util/StorageMonitor.kt
package com.ledplayer.util

import android.content.Context
import android.os.StatFs
import com.ledplayer.data.local.storage.MediaFileManager
import com.ledplayer.domain.model.StorageInfo
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class StorageMonitor(
    private val context: Context,
    private val mediaFileManager: MediaFileManager
) {
    private val _storageUpdates = MutableSharedFlow<StorageInfo>(replay = 1)
    val storageUpdates: SharedFlow<StorageInfo> = _storageUpdates.asSharedFlow()
    
    private val storageCheckInterval = 30_000L // 30 seconds
    
    init {
        startMonitoring()
    }
    
    private fun startMonitoring() {
        CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                val storageInfo = getStorageInfo()
                _storageUpdates.emit(storageInfo)
                delay(storageCheckInterval)
            }
        }
    }
    
    fun getStorageInfo(): StorageInfo {
        val mediaDir = mediaFileManager.getMediaDirectory()
        val stat = StatFs(mediaDir.path)
        
        val totalSpace = stat.totalBytes
        val freeSpace = stat.availableBytes
        val usedSpace = totalSpace - freeSpace
        
        return StorageInfo(
            totalSpace = totalSpace,
            freeSpace = freeSpace,
            usedSpace = usedSpace,
            usedByApp = calculateAppStorage()
        )
    }
    
    private fun calculateAppStorage(): Long {
        val mediaDir = mediaFileManager.getMediaDirectory()
        return mediaDir.walkTopDown()
            .filter { it.isFile }
            .map { it.length() }
            .sum()
    }
}
```

### Media File Manager

```kotlin
// data/local/storage/MediaFileManager.kt
package com.ledplayer.data.local.storage

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber
import java.io.File
import java.security.MessageDigest

class MediaFileManager(private val context: Context, private val okHttpClient: OkHttpClient) {
    
    private val mediaDir = File(context.getExternalFilesDir(null), "media")
    private val screenshotDir = File(context.getExternalFilesDir(null), "screenshots")
    
    init {
        mediaDir.mkdirs()
        screenshotDir.mkdirs()
    }
    
    fun getMediaDirectory(): File = mediaDir
    
    fun getScreenshotDirectory(): File = screenshotDir
    
    suspend fun downloadMedia(
        url: String,
        mediaId: Int,
        onProgress: (progress: Int) -> Unit = {}
    ): String? = withContext(Dispatchers.IO) {
        try {
            val fileName = url.substringAfterLast("/")
            val file = File(mediaDir, "${mediaId}_$fileName")
            
            if (file.exists()) {
                Timber.d("File already exists: ${file.absolutePath}")
                return@withContext file.absolutePath
            }
            
            val request = Request.Builder().url(url).build()
            val response = okHttpClient.newCall(request).execute()
            
            if (response.isSuccessful) {
                val body = response.body ?: return@withContext null
                val totalBytes = body.contentLength()
                var downloadedBytes = 0L
                
                file.outputStream().use { output ->
                    body.byteStream().use { input ->
                        val buffer = ByteArray(8192)
                        var bytes = input.read(buffer)
                        while (bytes >= 0) {
                            output.write(buffer, 0, bytes)
                            downloadedBytes += bytes
                            
                            if (totalBytes > 0) {
                                val progress = ((downloadedBytes * 100) / totalBytes).toInt()
                                onProgress(progress)
                            }
                            
                            bytes = input.read(buffer)
                        }
                    }
                }
                
                Timber.d("Downloaded media: ${file.absolutePath}")
                file.absolutePath
            } else {
                Timber.e("Download failed with code: ${response.code}")
                null
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to download media")
            null
        }
    }
    
    fun getMediaPath(mediaId: Int): String? {
        return mediaDir.listFiles()
            ?.firstOrNull { it.name.startsWith("${mediaId}_") }
            ?.absolutePath
    }
    
    fun deletePlaylistMedia(playlistId: Int) {
        // Implementation for deleting specific playlist media
    }
    
    fun verifyChecksum(filePath: String, expectedChecksum: String?): Boolean {
        if (expectedChecksum.isNullOrEmpty()) return true
        
        return try {
            val file = File(filePath)
            val digest = MessageDigest.getInstance("MD5")
            val inputStream = file.inputStream()
            val buffer = ByteArray(8192)
            var read = inputStream.read(buffer)
            
            while (read > 0) {
                digest.update(buffer, 0, read)
                read = inputStream.read(buffer)
            }
            
            val md5sum = digest.digest().joinToString("") { "%02x".format(it) }
            md5sum.equals(expectedChecksum, ignoreCase = true)
        } catch (e: Exception) {
            Timber.e(e, "Failed to verify checksum")
            false
        }
    }
}
```

### Screenshot Capture

```kotlin
// util/ScreenshotCapture.kt
package com.ledplayer.util

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream

class ScreenshotCapture(private val context: Context) {
    
    private val screenshotDir = File(context.getExternalFilesDir(null), "screenshots")
    
    init {
        screenshotDir.mkdirs()
    }
    
    fun captureScreen(): File? {
        val activity = context as? Activity ?: return null
        
        return try {
            val rootView = activity.window.decorView.rootView
            rootView.isDrawingCacheEnabled = true
            val bitmap = Bitmap.createBitmap(rootView.drawingCache)
            rootView.isDrawingCacheEnabled = false
            
            val timestamp = System.currentTimeMillis()
            val fileName = "screenshot_$timestamp.jpg"
            val file = File(screenshotDir, fileName)
            
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            }
            
            bitmap.recycle()
            Timber.d("Screenshot captured: ${file.absolutePath}")
            file
        } catch (e: Exception) {
            Timber.e(e, "Failed to capture screenshot")
            null
        }
    }
}
```

### Network Monitor

```kotlin
// util/NetworkMonitor.kt
package com.ledplayer.util

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import androidx.core.content.getSystemService
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

class NetworkMonitor(private val context: Context) {
    
    private val connectivityManager = context.getSystemService<ConnectivityManager>()
    
    val isConnected: Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(true)
            }
            
            override fun onLost(network: Network) {
                trySend(false)
            }
        }
        
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        
        connectivityManager?.registerNetworkCallback(request, callback)
        
        // Send initial state
        trySend(isCurrentlyConnected())
        
        awaitClose {
            connectivityManager?.unregisterNetworkCallback(callback)
        }
    }
    
    private fun isCurrentlyConnected(): Boolean {
        val network = connectivityManager?.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
}
```

---

## 🎬 Media Player

### Media Player Manager

```kotlin
// presentation/player/MediaPlayerManager.kt
package com.ledplayer.presentation.player

import android.app.Activity
import android.content.Context
import android.net.Uri
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ui.PlayerView
import com.ledplayer.data.remote.websocket.WebSocketManager
import com.ledplayer.domain.model.*
import com.ledplayer.domain.repository.ScreenshotRepository
import com.ledplayer.presentation.player.components.TextOverlayView
import com.ledplayer.util.ScreenshotCapture
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import java.io.File

class MediaPlayerManager(
    private val context: Context,
    private val webSocketManager: WebSocketManager,
    private val screenshotCapture: ScreenshotCapture,
    private val screenshotRepository: ScreenshotRepository
) {
    private var exoPlayer: ExoPlayer? = null
    private var currentPlaylist: Playlist? = null
    private var currentMediaIndex: Int = 0
    private var textOverlayView: TextOverlayView? = null
    private var imageDisplayJob: Job? = null
    
    private val _playbackState = MutableStateFlow<PlaybackState>(PlaybackState.Idle)
    val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()
    
    fun initialize(playerView: PlayerView, overlayView: TextOverlayView, playlist: Playlist) {
        currentPlaylist = playlist
        currentMediaIndex = 0
        textOverlayView = overlayView
        
        exoPlayer = ExoPlayer.Builder(context).build().apply {
            playerView.player = this
        }
        
        playCurrentMedia()
    }
    
    private fun playCurrentMedia() {
        val playlist = currentPlaylist ?: return
        if (playlist.media.isEmpty()) return
        
        val media = playlist.media[currentMediaIndex]
        
        when (media.mediaType) {
            MediaType.VIDEO -> playVideo(media)
            MediaType.IMAGE -> displayImage(media)
        }
        
        _playbackState.value = PlaybackState.Playing(
            playlistId = playlist.id,
            mediaId = media.id,
            mediaIndex = currentMediaIndex
        )
        
        webSocketManager.sendDeviceStatus(
            currentPlaylistId = playlist.id,
            currentMediaId = media.id,
            playbackState = "playing"
        )
        
        captureAndUploadScreenshot(media)
    }
    
    private fun playVideo(media: Media) {
        val localPath = media.localPath
        if (localPath.isNullOrEmpty()) {
            Timber.e("Video local path is null for media ${media.id}")
            playNext()
            return
        }
        
        val file = File(localPath)
        if (!file.exists()) {
            Timber.e("Video file does not exist: $localPath")
            playNext()
            return
        }
        
        val mediaItem = MediaItem.fromUri(Uri.fromFile(file))
        
        exoPlayer?.apply {
            setMediaItem(mediaItem)
            prepare()
            playWhenReady = true
            
            addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    if (playbackState == Player.STATE_ENDED) {
                        playNext()
                    }
                }
                
                override fun onPlayerError(error: PlaybackException) {
                    Timber.e(error, "Video playback error: ${media.name}")
                    playNext()
                }
            })
        }
    }
    
    private fun displayImage(media: Media) {
        imageDisplayJob?.cancel()
        imageDisplayJob = CoroutineScope(Dispatchers.Main).launch {
            // Load and display image using Coil or Glide
            // For now, just wait for duration
            delay(media.duration * 1000L)
            playNext()
        }
    }
    
    fun playNext() {
        val playlist = currentPlaylist ?: return
        currentMediaIndex = (currentMediaIndex + 1) % playlist.media.size
        playCurrentMedia()
    }
    
    fun playPrevious() {
        val playlist = currentPlaylist ?: return
        currentMediaIndex = if (currentMediaIndex == 0) {
            playlist.media.size - 1
        } else {
            currentMediaIndex - 1
        }
        playCurrentMedia()
    }
    
    fun play() {
        exoPlayer?.playWhenReady = true
        updatePlaybackState("playing")
    }
    
    fun pause() {
        exoPlayer?.playWhenReady = false
        _playbackState.value = PlaybackState.Paused(
            playlistId = currentPlaylist?.id ?: 0,
            mediaId = currentPlaylist?.media?.get(currentMediaIndex)?.id ?: 0,
            mediaIndex = currentMediaIndex
        )
        updatePlaybackState("paused")
    }
    
    fun switchPlaylist(playlist: Playlist) {
        currentPlaylist = playlist
        currentMediaIndex = 0
        playCurrentMedia()
    }
    
    fun playSpecificMedia(mediaId: Int?, mediaIndex: Int?) {
        val playlist = currentPlaylist ?: return
        
        val index = when {
            mediaIndex != null -> mediaIndex
            mediaId != null -> playlist.media.indexOfFirst { it.id == mediaId }
            else -> return
        }
        
        if (index in playlist.media.indices) {
            currentMediaIndex = index
            playCurrentMedia()
        }
    }
    
    fun showTextOverlay(overlay: TextOverlay) {
        textOverlayView?.show(overlay)
    }
    
    fun hideTextOverlay() {
        textOverlayView?.hide()
    }
    
    fun setBrightness(level: Int) {
        val activity = context as? Activity ?: return
        val layoutParams = activity.window.attributes
        layoutParams.screenBrightness = level / 100f
        activity.window.attributes = layoutParams
    }
    
    fun setVolume(level: Int) {
        exoPlayer?.volume = level / 100f
    }
    
    private fun updatePlaybackState(state: String) {
        webSocketManager.sendDeviceStatus(
            currentPlaylistId = currentPlaylist?.id,
            currentMediaId = currentPlaylist?.media?.get(currentMediaIndex)?.id,
            playbackState = state
        )
    }
    
    private fun captureAndUploadScreenshot(media: Media) {
        CoroutineScope(Dispatchers.IO).launch {
            delay(1000)
            
            try {
                val screenshotFile = screenshotCapture.captureScreen()
                if (screenshotFile != null) {
                    screenshotRepository.uploadScreenshot(
                        mediaId = media.id,
                        screenshotFile = screenshotFile
                    )
                    Timber.d("Screenshot uploaded for media ${media.id}")
                }
            } catch (e: Exception) {
                Timber.e(e, "Failed to capture/upload screenshot")
            }
        }
    }
    
    fun release() {
        imageDisplayJob?.cancel()
        exoPlayer?.release()
        exoPlayer = null
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
```

### Text Overlay View

```kotlin
// presentation/player/components/TextOverlayView.kt
package com.ledplayer.presentation.player.components

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.view.Gravity
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import com.ledplayer.domain.model.TextOverlay

class TextOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : FrameLayout(context, attrs) {
    
    private val textView: TextView
    private var scrollAnimator: ValueAnimator? = null
    
    init {
        textView = TextView(context).apply {
            textSize = 24f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.BLACK)
            setPadding(16, 8, 16, 8)
        }
        addView(textView)
        visibility = GONE
    }
    
    fun show(overlay: TextOverlay) {
        textView.apply {
            text = overlay.text
            textSize = overlay.fontSize.toFloat()
            setTextColor(Color.parseColor(overlay.textColor))
            setBackgroundColor(Color.parseColor(overlay.backgroundColor))
        }
        
        val layoutParams = textView.layoutParams as LayoutParams
        layoutParams.gravity = when (overlay.position) {
            com.ledplayer.domain.model.TextPosition.TOP -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
            com.ledplayer.domain.model.TextPosition.BOTTOM -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            com.ledplayer.domain.model.TextPosition.LEFT -> Gravity.START or Gravity.CENTER_VERTICAL
            com.ledplayer.domain.model.TextPosition.RIGHT -> Gravity.END or Gravity.CENTER_VERTICAL
        }
        textView.layoutParams = layoutParams
        
        if (overlay.animation == com.ledplayer.domain.model.TextAnimation.SCROLL) {
            startScrollAnimation(overlay.speed)
        }
        
        visibility = VISIBLE
    }
    
    fun hide() {
        visibility = GONE
        scrollAnimator?.cancel()
    }
    
    private fun startScrollAnimation(speed: Float) {
        scrollAnimator?.cancel()
        
        scrollAnimator = ValueAnimator.ofFloat(width.toFloat(), -textView.width.toFloat()).apply {
            duration = ((width + textView.width) / speed * 1000).toLong()
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()
            
            addUpdateListener { animation ->
                textView.translationX = animation.animatedValue as Float
            }
            
            start()
        }
    }
}
```

---

## 📱 Presentation Layer

### PlayerViewModel

```kotlin
// presentation/player/PlayerViewModel.kt
package com.ledplayer.presentation.player

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ledplayer.data.remote.websocket.WebSocketManager
import com.ledplayer.domain.model.*
import com.ledplayer.domain.repository.DeviceRepository
import com.ledplayer.domain.repository.PlaylistRepository
import com.ledplayer.util.NetworkMonitor
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber

class PlayerViewModel(
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
                handleWebSocketCommand(command)
            }
        }
    }
    
    private fun observeNetworkChanges() {
        viewModelScope.launch {
            networkMonitor.isConnected.collect { isConnected ->
                if (isConnected) {
                    webSocketManager.connect()
                    syncPlaylists()
                }
            }
        }
    }
    
    fun loadCurrentPlaylist() {
        viewModelScope.launch {
            try {
                val playlists = playlistRepository.getPlaylists()
                val current = playlists.firstOrNull { it.isActive } ?: playlists.firstOrNull()
                _currentPlaylist.value = current
            } catch (e: Exception) {
                Timber.e(e, "Failed to load current playlist")
            }
        }
    }
    
    private suspend fun handleWebSocketCommand(command: WebSocketCommand) {
        when (command) {
            is WebSocketCommand.Play -> _playerCommand.emit(PlayerCommand.Play)
            is WebSocketCommand.Pause -> _playerCommand.emit(PlayerCommand.Pause)
            is WebSocketCommand.Next -> _playerCommand.emit(PlayerCommand.Next)
            is WebSocketCommand.Previous -> _playerCommand.emit(PlayerCommand.Previous)
            is WebSocketCommand.ReloadPlaylist -> reloadPlaylist()
            is WebSocketCommand.SwitchPlaylist -> switchPlaylist(command.playlistId)
            is WebSocketCommand.PlayMedia -> _playerCommand.emit(
                PlayerCommand.PlaySpecificMedia(command.mediaId, command.mediaIndex)
            )
            is WebSocketCommand.ShowTextOverlay -> _playerCommand.emit(
                PlayerCommand.ShowTextOverlay(command.textOverlay)
            )
            is WebSocketCommand.HideTextOverlay -> _playerCommand.emit(PlayerCommand.HideTextOverlay)
            is WebSocketCommand.SetBrightness -> _playerCommand.emit(
                PlayerCommand.SetBrightness(command.brightness)
            )
            is WebSocketCommand.SetVolume -> _playerCommand.emit(
                PlayerCommand.SetVolume(command.volume)
            )
            is WebSocketCommand.CleanupOldPlaylists -> cleanupOldPlaylists(command.playlistIdsToKeep)
        }
    }
    
    private suspend fun reloadPlaylist() {
        val currentPlaylist = _currentPlaylist.value ?: return
        playlistRepository.downloadPlaylist(currentPlaylist.id)
        loadCurrentPlaylist()
    }
    
    private suspend fun switchPlaylist(playlistId: Int) {
        val playlist = playlistRepository.getPlaylist(playlistId)
        
        if (playlist.downloadStatus != DownloadStatus.READY) {
            playlistRepository.downloadPlaylist(playlistId)
        }
        
        _currentPlaylist.value = playlist
    }
    
    private suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>) {
        playlistRepository.cleanupOldPlaylists(playlistIdsToKeep)
    }
    
    private suspend fun syncPlaylists() {
        try {
            playlistRepository.syncPlaylists()
        } catch (e: Exception) {
            Timber.e(e, "Failed to sync playlists")
        }
    }
}

sealed class PlayerCommand {
    object Play : PlayerCommand()
    object Pause : PlayerCommand()
    object Next : PlayerCommand()
    object Previous : PlayerCommand()
    data class PlaySpecificMedia(val mediaId: Int?, val mediaIndex: Int?) : PlayerCommand()
    data class ShowTextOverlay(val overlay: TextOverlay) : PlayerCommand()
    object HideTextOverlay : PlayerCommand()
    data class SetBrightness(val brightness: Int) : PlayerCommand()
    data class SetVolume(val volume: Int) : PlayerCommand()
}
```

### SplashViewModel

```kotlin
// presentation/splash/SplashViewModel.kt
package com.ledplayer.presentation.splash

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ledplayer.data.remote.websocket.WebSocketManager
import com.ledplayer.domain.model.DownloadStatus
import com.ledplayer.domain.repository.AuthRepository
import com.ledplayer.domain.repository.DeviceRepository
import com.ledplayer.domain.repository.PlaylistRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import timber.log.Timber

class SplashViewModel(
    private val authRepository: AuthRepository,
    private val deviceRepository: DeviceRepository,
    private val playlistRepository: PlaylistRepository,
    private val webSocketManager: WebSocketManager
) : ViewModel() {
    
    fun initializeApp(): Flow<AppState> = flow {
        try {
            // Check authentication
            if (!authRepository.isAuthenticated()) {
                emit(AppState.NeedsAuth)
                return@flow
            }
            
            // Refresh token if needed
            authRepository.refreshTokenIfNeeded()
            
            // Check device registration
            if (!deviceRepository.isDeviceRegistered()) {
                deviceRepository.registerDevice()
            }
            
            // Connect WebSocket
            webSocketManager.connect()
            
            // Load playlists
            val playlists = playlistRepository.getPlaylists()
            
            // Download current playlist if needed
            val currentPlaylist = playlists.firstOrNull { it.isActive } ?: playlists.firstOrNull()
            if (currentPlaylist == null) {
                emit(AppState.Error("No playlists available"))
                return@flow
            }
            
            if (currentPlaylist.downloadStatus != DownloadStatus.READY) {
                playlistRepository.downloadPlaylist(currentPlaylist.id)
            }
            
            // Start background download for remaining playlists
            viewModelScope.launch {
                playlistRepository.downloadRemainingPlaylistsInBackground()
            }
            
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
```

---

## 🛠️ Dependencies (build.gradle.kts)

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt")
    id("com.google.dagger.hilt.android")
}

android {
    namespace = "com.ledplayer"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.ledplayer"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    
    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // Core Android
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    
    // Lifecycle
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    implementation("androidx.activity:activity-ktx:1.8.2")
    implementation("androidx.fragment:fragment-ktx:1.6.2")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // Room Database
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")
    
    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // JSON
    implementation("com.google.code.gson:gson:2.10.1")
    
    // Media Player (ExoPlayer)
    implementation("com.google.android.exoplayer:exoplayer:2.19.1")
    implementation("com.google.android.exoplayer:exoplayer-core:2.19.1")
    implementation("com.google.android.exoplayer:exoplayer-ui:2.19.1")
    
    // Image Loading
    implementation("io.coil-kt:coil:2.5.0")
    
    // Dependency Injection (Hilt)
    implementation("com.google.dagger:hilt-android:2.50")
    kapt("com.google.dagger:hilt-compiler:2.50")
    
    // Encrypted SharedPreferences
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // WorkManager
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    
    // Logging
    implementation("com.jakewharton.timber:timber:5.0.1")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

---

## 📋 Implementation Checklist

### Phase 1: Project Setup
- [ ] Create project structure
- [ ] Add dependencies
- [ ] Setup Hilt DI
- [ ] Initialize Timber logging
- [ ] Create base classes

### Phase 2: Data Layer
- [ ] Create Room database entities
- [ ] Create DAOs
- [ ] Create API interfaces
- [ ] Implement repositories
- [ ] Setup EncryptedSharedPreferences

### Phase 3: Domain Layer
- [ ] Create all domain models
- [ ] Create repository interfaces
- [ ] Implement use cases

### Phase 4: Authentication
- [ ] Implement login
- [ ] Implement token storage
- [ ] Implement auto-refresh with WorkManager
- [ ] Test authentication flow

### Phase 5: Device Management
- [ ] Generate unique SN number
- [ ] Implement device registration
- [ ] Store device info locally

### Phase 6: Playlist Management
- [ ] Implement playlist API integration
- [ ] Create download manager
- [ ] Implement file storage
- [ ] Add checksum verification
- [ ] Test download flow

### Phase 7: WebSocket
- [ ] Implement WebSocket connection
- [ ] Handle incoming commands
- [ ] Send status updates
- [ ] Implement auto-reconnect
- [ ] Test all commands

### Phase 8: Media Player
- [ ] Integrate ExoPlayer
- [ ] Implement video playback
- [ ] Implement image display
- [ ] Add playlist navigation
- [ ] Test playback

### Phase 9: Advanced Features
- [ ] Implement text overlay
- [ ] Add brightness control
- [ ] Add volume control
- [ ] Implement screenshot capture
- [ ] Add storage monitoring

### Phase 10: UI & Activities
- [ ] Create SplashActivity
- [ ] Create AuthActivity
- [ ] Create PlayerActivity
- [ ] Implement ViewModels
- [ ] Add UI components

### Phase 11: Testing
- [ ] Unit tests for UseCases
- [ ] Integration tests for Repositories
- [ ] UI tests for critical flows
- [ ] Network tests
- [ ] Edge case testing

### Phase 12: Optimization
- [ ] Performance profiling
- [ ] Memory leak detection
- [ ] Battery usage optimization
- [ ] Network usage optimization
- [ ] Storage optimization

---

## 🎯 Key Implementation Notes

### 1. Offline-First Strategy
- Always use local database as source of truth
- Sync with backend when network available
- Queue operations when offline
- Implement conflict resolution

### 2. Auto-Recovery Mechanisms
- WebSocket: Auto-reconnect with exponential backoff
- Auth: Auto-refresh tokens daily
- Downloads: Resume failed downloads
- Network: Monitor and auto-sync when restored

### 3. Silent Error Handling
- Never show error dialogs to user
- Log all errors with Timber
- Implement graceful degradation
- Skip problematic media items

### 4. Performance Optimizations
- Use Flow for reactive data
- Implement pagination where needed
- Lazy load media files
- Release resources properly
- Use WorkManager for background tasks

### 5. Security Best Practices
- Encrypt tokens with EncryptedSharedPreferences
- Use HTTPS/WSS only
- Validate all WebSocket commands
- Sanitize user inputs
- Implement certificate pinning (optional)

---

## 🔍 Testing Strategy

### Unit Tests
```kotlin
// Example: PlaylistRepositoryTest
class PlaylistRepositoryTest {
    @Test
    fun `test download playlist success`() = runTest {
        // Arrange
        val playlist = mockPlaylist()
        
        // Act
        val result = repository.downloadPlaylist(playlist.id)
        
        // Assert
        assertTrue(result.isSuccess)
    }
}
```

### Integration Tests
```kotlin
// Example: WebSocketIntegrationTest
class WebSocketIntegrationTest {
    @Test
    fun `test websocket command handling`() = runTest {
        // Test full WebSocket flow
    }
}
```

---

## 📝 Important Business Rules

1. **Playlist Priority**: Active playlist is always played first
2. **Loop Playback**: Playlist repeats infinitely
3. **Storage Management**: Old playlists cleaned via WebSocket command
4. **Screenshot Timing**: Capture 1 second after video starts
5. **Storage Updates**: Send every 30 seconds via WebSocket
6. **Download Strategy**: Current playlist first, then background downloads
7. **Checksum Verification**: Always verify after download
8. **Network Resilience**: Work offline indefinitely

---

## 🚀 Ready for Development!

This specification contains everything needed to build a production-ready Android LED Player application. Follow the implementation checklist and refer to the code examples for guidance.

**Good luck with development! 🎉**
