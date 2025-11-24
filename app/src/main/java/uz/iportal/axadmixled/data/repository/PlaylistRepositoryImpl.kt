package uz.iportal.axadmixled.data.repository

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import timber.log.Timber
import uz.iportal.axadmixled.data.local.database.dao.MediaDao
import uz.iportal.axadmixled.data.local.database.dao.PlaylistDao
import uz.iportal.axadmixled.data.local.database.entities.MediaEntity
import uz.iportal.axadmixled.data.local.database.entities.PlaylistEntity
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.data.local.storage.MediaFileManager
import uz.iportal.axadmixled.data.remote.api.PlaylistApi
import uz.iportal.axadmixled.data.remote.websocket.WebSocketManager
import uz.iportal.axadmixled.domain.model.DownloadStatus
import uz.iportal.axadmixled.domain.model.Media
import uz.iportal.axadmixled.domain.model.MediaType
import uz.iportal.axadmixled.domain.model.Playlist
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import uz.iportal.axadmixled.util.Constants
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton

private const val TAG = "PlaylistRepository"

@Singleton
class PlaylistRepositoryImpl @Inject constructor(
    private val playlistApiProvider: Provider<PlaylistApi>,
    private val playlistDao: PlaylistDao,
    private val mediaDao: MediaDao,
    private val authPreferences: AuthPreferences,
    private val mediaFileManager: MediaFileManager,
    private val webSocketManager: WebSocketManager
) : PlaylistRepository {
    private val gson = Gson()
    private val mutexSync = Mutex()
    private val mutexDownload = Mutex()

    override suspend fun syncPlaylists(forceRenew: Boolean): Result<Unit> {
        return mutexSync.withLock {
            syncPlaylistsInner(forceRenew)
        }
    }

    private suspend fun syncPlaylistsInner(forceRenew: Boolean): Result<Unit> {
        return try {
            val accessToken = authPreferences.getAccessToken()
            val snNumber = authPreferences.getDeviceSnNumber()

            if (accessToken.isNullOrEmpty() || snNumber.isNullOrEmpty()) {
                Timber.tag(TAG).e("Missing authentication or device SN for playlist sync")
                return Result.failure(Exception("Not authenticated or device not registered"))
            }

            Timber.tag(TAG).d("Syncing playlists for device: $snNumber, forced: $forceRenew")

            val syncedWithin = System.currentTimeMillis() - (playlistDao.getOldestSyncTime() ?: 0L)
            if (!forceRenew && syncedWithin < Constants.SYNC_INTERVAL_MIN) {
                Timber.tag(TAG).w("Last sync time was too recent: $syncedWithin ms ago")
                return Result.success(Unit)
            }

            val response = playlistApiProvider.get().getPlaylists(
                token = "Bearer $accessToken",
                snNumber = snNumber
            )

            Timber.tag(TAG).d("Fetched ${response.frontScreen.countPlaylist} playlists from server")

            // Convert and save playlists to database
            val resolution = response.frontScreen.resolution
            val playlistEntities = response.frontScreen.playlists.map { playlistDetail ->
                // Get existing playlist to preserve download status
                val existing = playlistDao.getPlaylistById(playlistDetail.id)

                PlaylistEntity(
                    id = playlistDetail.id,
                    name = playlistDetail.name,
                    description = playlistDetail.name,
                    isActive = playlistDetail.status.isReady,
                    priority = existing?.priority ?: playlistDetail.id,
                    duration = playlistDetail.duration,
                    mediaCount = playlistDetail.countMediaItems,
                    createdAt = playlistDetail.name,
                    updatedAt = playlistDetail.name,
                    downloadStatus = existing?.downloadStatus ?: DownloadStatus.PENDING.name,
                    missingFiles = existing?.missingFiles,
                    lastSyncedAt = System.currentTimeMillis()
                )
            }

            Timber.tag(TAG).d(playlistEntities.toString())
            playlistDao.insertPlaylists(playlistEntities)

            // Save media items for each playlist
            response.frontScreen.playlists.forEach { playlistDetail ->
                val mediaEntities = playlistDetail.mediaItems.map { mediaDetail ->
                    // Check if media already exists locally
                    val existingMedia = mediaDao.getMediaById(mediaDetail.mediaId)
                    val localPath = existingMedia?.localPath
                        ?: mediaFileManager.getMediaPath(mediaDetail.mediaId)

                    val isDownloaded = mediaFileManager.verifyChecksum(localPath ?: "", mediaDetail.checksum)

                    val entity = MediaEntity(
                        id = mediaDetail.mediaId,
                        playlistId = playlistDetail.id,
                        name = mediaDetail.mediaName,
                        description = mediaDetail.mediaName,
                        file = mediaDetail.mediaUrl,
                        thumbnail = mediaDetail.mediaUrl,
                        mediaType = mediaDetail.mediaType,
                        duration = mediaDetail.nTimePlay,
                        fileSize = mediaDetail.fileSize.toLong(),
                        resolution = resolution,
                        checksum = mediaDetail.checksum,
                        order = mediaDetail.order,
                        createdAt = mediaDetail.downloadDate,
                        updatedAt = mediaDetail.downloadDate,
                        localPath = localPath,
                        isDownloaded = isDownloaded,
                        downloadedAt = existingMedia?.downloadedAt,
                        downloadProgress = existingMedia?.downloadProgress ?: 0
                    )
                    Timber.tag(TAG).d("Existing media: $existingMedia")
                    Timber.tag(TAG).d("Updated media : $entity")
                    entity
                }

                mediaDao.insertMediaList(mediaEntities)
                Timber.tag(TAG).d("Updated ${mediaEntities.size} media for playlist ${playlistDetail.id}")
            }

            Timber.tag(TAG).d("Playlists synced successfully. Total: ${playlistEntities.size}")
            webSocketManager.sendReadyPlaylists()
            Result.success(Unit)
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to sync playlists")
            Result.failure(e)
        }
    }

    override suspend fun getActivePlaylist(): Playlist? {
        val current = playlistDao.getActivePlaylist() ?: return null

        Timber.tag(TAG).d("Loaded active playlist: ${current.name} (id=${current.id})")
        if (DownloadStatus.READY.name != current.downloadStatus) {
            Timber.tag(TAG).d("Current playlist not ready, downloading: ${current.id}")
            downloadPlaylist(current.id)
        }

        try {
            return mapEntityToDomain(current)
        } catch (e: IllegalArgumentException) {
            playlistDao.updatePlaylist(current.copy(isActive = false))
            Timber.tag(TAG).e(e, "Skipping to next active, ${current.id} is deactivated")
            return getActivePlaylist()
        }
    }

    override suspend fun getPlaylists(): List<Playlist> {
        return try {
            val playlistEntities = playlistDao.getAllPlaylists()
            playlistEntities.map { entity -> mapEntityToDomain(entity) }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to get playlists from database")
            emptyList()
        }
    }

    override fun getPlaylistsFlow(): Flow<List<Playlist>> {
        return playlistDao.getAllPlaylistsFlow().map { entities ->
            entities.map { entity -> mapEntityToDomain(entity) }
        }
    }

    override suspend fun switchPlaylist(playlistId: Int): Playlist? {
        val entity = playlistDao.getPlaylistById(playlistId)
        val playlist = if (entity == null) {
            syncPlaylists(forceRenew = true)
            playlistDao.getPlaylistById(playlistId) ?: return null
        } else entity


        Timber.tag(TAG).d("Loaded playlist: ${playlist.name} (id=${playlist.id})")
        if (DownloadStatus.READY.name != playlist.downloadStatus) {
            Timber.tag(TAG).d("Playlist not ready, downloading: ${playlist.id}")
            downloadPlaylist(playlist.id)
        }

        playlistDao.prioritize(playlist.id, Int.MAX_VALUE)
        return mapEntityToDomain(playlist)
    }

    override suspend fun downloadPlaylist(playlistId: Int): Result<Unit> {
        return mutexDownload.withLock {
            downloadPlaylistInner(playlistId)
        }
    }

    private suspend fun downloadPlaylistInner(playlistId: Int): Result<Unit> {
        return try {
            Timber.tag(TAG).d("Starting download for playlist: $playlistId")

            if (DownloadStatus.READY.name == playlistDao.getDownloadStatusById(playlistId)) {
                Timber.tag(TAG).d("Playlist: $playlistId is already downloaded, skipping")
                return Result.success(Unit)
            }

            // Update status to DOWNLOADING
            playlistDao.updateDownloadStatus(
                playlistId = playlistId,
                status = DownloadStatus.DOWNLOADING.name,
            )

            val mediaList = mediaDao.getMediaByPlaylistId(playlistId)
            var downloadedCount = 0
            val missingFiles = mutableListOf<String>()

            Timber.tag(TAG).d("Medias to download: ${mediaList.size}")
            for (media in mediaList) {
                try {
                    // Skip if already downloaded
                    if (media.isDownloaded && !media.localPath.isNullOrEmpty()) {
                        val file = java.io.File(media.localPath)
                        if (file.exists()) {
                            downloadedCount++
                            continue
                        }
                    }

                    Timber.tag(TAG).d("URL: Downloading media: ${media.name} (${media.id})")

                    // throttle logging
                    var lastLogged = -1
                    val localPath = mediaFileManager.downloadMedia(
                        url = media.file,
                        mediaId = media.id
                    ) { progress ->
                        val throttled = progress / 5 // log every 5%
                        if (throttled != lastLogged) {
                            lastLogged = throttled
                            Timber.tag(TAG).v("Download progress for ${media.id}: $progress%")
                        }
                    }

                    if (localPath != null) {
                        // Verify checksum if available
                        val isValid = mediaFileManager.verifyChecksum(localPath, media.checksum)

                        if (isValid) {
                            mediaDao.markAsDownloaded(
                                mediaId = media.id,
                                localPath = localPath,
                                downloadedAt = System.currentTimeMillis()
                            )
                            downloadedCount++
                            Timber.tag(TAG).d("Media downloaded successfully: ${media.name}")
                        } else {
                            Timber.tag(TAG).e("Checksum verification failed for media: ${media.name}")
                            missingFiles.add(media.name)
                        }
                    } else {
                        Timber.tag(TAG).e("Failed to download media: ${media.name}")
                        missingFiles.add(media.name)
                    }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Timber.tag(TAG).e(e, "Error downloading media: ${media.name}")
                    missingFiles.add(media.name)
                }
            }

            // Update playlist download status
            val finalStatus = when {
                downloadedCount == mediaList.size -> DownloadStatus.READY
                downloadedCount > 0 -> DownloadStatus.PARTIAL
                else -> DownloadStatus.FAILED
            }

            val playlist = playlistDao.getPlaylistById(playlistId)
            if (playlist != null) {
                val updatedPlaylist = playlist.copy(
                    downloadStatus = finalStatus.name,
                    missingFiles = if (missingFiles.isNotEmpty()) {
                        gson.toJson(missingFiles)
                    } else null
                )
                playlistDao.updatePlaylist(updatedPlaylist)
            }

            Timber.tag(TAG).d("Playlist download completed: $downloadedCount/${mediaList.size} items")
            Result.success(Unit)
        } catch (e: CancellationException) {
            Timber.tag(TAG).e("Download playlist: $playlistId cancelled due to coroutine cancellation")
            playlistDao.updateDownloadStatus(
                playlistId = playlistId,
                status = DownloadStatus.FAILED.name,
            )
            throw e
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to download playlist: $playlistId")

            // Update status to FAILED
            playlistDao.updateDownloadStatus(
                playlistId = playlistId,
                status = DownloadStatus.FAILED.name,
            )

            Result.failure(e)
        }
    }

    override suspend fun downloadRemainingPlaylistsInBackground() {
        withContext(Dispatchers.IO) {
            try {
                Timber.tag(TAG).d("Starting background download for remaining playlists")
                val playlists = playlistDao.getAllPlaylists()

                for (playlist in playlists) {
                    // Skip playlists that are already READY
                    if (playlist.downloadStatus == DownloadStatus.READY.name) {
                        continue
                    }

                    Timber.tag(TAG).d("Background downloading playlist: ${playlist.name}")
                    downloadPlaylist(playlist.id)
                }

                Timber.tag(TAG).d("Background playlist downloads completed")
            } catch (e: Exception) {
                Timber.tag(TAG).e(e, "Error in background playlist download")
            }
        }
    }

    override suspend fun deactivatePlaylist(playlistId: Int) {
        playlistDao.getPlaylistById(playlistId)?.let {
            playlistDao.updatePlaylist(it.copy(isActive = false))
        }
    }

    override suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>) {
        try {
            Timber.tag(TAG).d("Cleaning up old playlists, keeping: $playlistIdsToKeep")

            // Get all playlists that will be deleted
            val allPlaylists = playlistDao.getAllPlaylists()
            val playlistsToDelete = allPlaylists.filter { it.id !in playlistIdsToKeep }

            // Delete media files for playlists to be removed
            for (playlist in playlistsToDelete) {
                val mediaList = mediaDao.getMediaByPlaylistId(playlist.id)
                for (media in mediaList) {
                    if (!media.localPath.isNullOrEmpty()) {
                        mediaFileManager.deleteMedia(media.localPath)
                    }
                }
            }

            // Delete playlists from database (cascade will delete media)
            if (playlistIdsToKeep.isNotEmpty()) {
                playlistDao.deletePlaylistsNotIn(playlistIdsToKeep)
            }

            Timber.tag(TAG).d("Old playlists cleaned up successfully")
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to cleanup old playlists")
        }
    }

    private suspend fun mapEntityToDomain(entity: PlaylistEntity): Playlist {
        val mediaEntities = mediaDao.getMediaByPlaylistId(entity.id)
        val mediaList = mediaEntities//.filter {
//            it.mediaType == MediaType.IMAGE.name || mediaFileManager.isCodecSupported(it.localPath)
        .map { mediaEntity ->
            Media(
                id = mediaEntity.id,
                name = mediaEntity.name,
                description = mediaEntity.description,
                file = mediaEntity.file,
                thumbnail = mediaEntity.thumbnail,
                mediaType = MediaType.fromString(mediaEntity.mediaType),
                duration = mediaEntity.duration,
                fileSize = mediaEntity.fileSize,
                resolution = mediaEntity.resolution,
                checksum = mediaEntity.checksum,
                order = mediaEntity.order,
                createdAt = mediaEntity.createdAt,
                updatedAt = mediaEntity.updatedAt,
                localPath = mediaEntity.localPath,
                isDownloaded = mediaEntity.isDownloaded,
                downloadedAt = mediaEntity.downloadedAt,
                downloadProgress = mediaEntity.downloadProgress
            )
        }

        require(mediaList.isNotEmpty()) { "No supported media for playlist" }

        val missingFilesList = if (!entity.missingFiles.isNullOrEmpty()) {
            try {
                val type = object : TypeToken<List<String>>() {}.type
                gson.fromJson<List<String>>(entity.missingFiles, type)
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }

        return Playlist(
            id = entity.id,
            name = entity.name,
            description = entity.description,
            isActive = entity.isActive,
            priority = entity.priority,
            duration = entity.duration,
            mediaCount = entity.mediaCount,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt,
            media = mediaList,
            downloadStatus = DownloadStatus.valueOf(entity.downloadStatus),
            missingFiles = missingFilesList,
            lastSyncedAt = entity.lastSyncedAt
        )
    }
}
