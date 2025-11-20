package uz.iportal.axadmixled.data.repository

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import timber.log.Timber
import uz.iportal.axadmixled.data.local.database.dao.MediaDao
import uz.iportal.axadmixled.data.local.database.dao.PlaylistDao
import uz.iportal.axadmixled.data.local.database.entities.MediaEntity
import uz.iportal.axadmixled.data.local.database.entities.PlaylistEntity
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.data.local.storage.MediaFileManager
import uz.iportal.axadmixled.data.remote.api.PlaylistApi
import uz.iportal.axadmixled.domain.model.DownloadStatus
import uz.iportal.axadmixled.domain.model.Media
import uz.iportal.axadmixled.domain.model.MediaType
import uz.iportal.axadmixled.domain.model.Playlist
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PlaylistRepositoryImpl @Inject constructor(
    private val playlistApi: PlaylistApi,
    private val playlistDao: PlaylistDao,
    private val mediaDao: MediaDao,
    private val authPreferences: AuthPreferences,
    private val mediaFileManager: MediaFileManager
) : PlaylistRepository {

    private val gson = Gson()

    override suspend fun syncPlaylists(): Result<Unit> {
        return try {
            val accessToken = authPreferences.getAccessToken()
            val snNumber = authPreferences.getDeviceSnNumber()

            if (accessToken.isNullOrEmpty() || snNumber.isNullOrEmpty()) {
                Timber.tag("APLAYLISTS").e("Missing authentication or device SN for playlist sync")
                return Result.failure(Exception("Not authenticated or device not registered"))
            }

            Timber.tag("APLAYLISTS").d("Syncing playlists for device: $snNumber")
            val response = withContext(Dispatchers.IO){
                playlistApi.getPlaylists(
                    token = "Bearer $accessToken",
                    snNumber = snNumber
                )
            }

            Timber.tag("APLAYLISTS").d("Fetched ${response.frontScreen.countPlaylist} playlists from server")

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
                    priority = playlistDetail.id,
                    duration = playlistDetail.duration,
                    mediaCount = playlistDetail.countMediaItems,
                    createdAt = playlistDetail.name,
                    updatedAt = playlistDetail.name,
                    downloadStatus = existing?.downloadStatus ?: DownloadStatus.PENDING.name,
                    downloadedItems = existing?.downloadedItems ?: 0,
                    missingFiles = existing?.missingFiles,
                    lastSyncedAt = System.currentTimeMillis()
                )
            }

            Timber.tag("APLAYLISTS").d(playlistEntities.toString())
            playlistDao.insertPlaylists(playlistEntities)

            // Save media items for each playlist
            response.frontScreen.playlists.forEach { playlistDetail ->
                val mediaEntities = playlistDetail.mediaItems.map { mediaDetail ->
                    // Check if media already exists locally
                    val existingMedia = mediaDao.getMediaById(mediaDetail.mediaId)
                    val localPath = existingMedia?.localPath
                        ?: mediaFileManager.getMediaPath(mediaDetail.mediaId)

                    MediaEntity(
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
                        localPath = mediaDetail.localPath,
                        isDownloaded = existingMedia?.isDownloaded ?: false,
                        downloadedAt = existingMedia?.downloadedAt,
                        downloadProgress = existingMedia?.downloadProgress ?: 0
                    )
                }

                mediaDao.insertMediaList(mediaEntities)
            }

            Timber.tag("APLAYLISTS").d("Playlists synced successfully")
            Result.success(Unit)
        } catch (e: Exception) {
            Timber.tag("APLAYLISTS").e(e, "Failed to sync playlists")
            Result.failure(e)
        }
    }

    override suspend fun getPlaylists(): List<Playlist> {
        return try {
            val playlistEntities = playlistDao.getAllPlaylists()
            playlistEntities.map { entity -> mapEntityToDomain(entity) }
        } catch (e: Exception) {
            Timber.tag("APLAYLISTS").e(e, "Failed to get playlists from database")
            emptyList()
        }
    }

    override fun getPlaylistsFlow(): Flow<List<Playlist>> {
        return playlistDao.getAllPlaylistsFlow().map { entities ->
            entities.map { entity -> mapEntityToDomain(entity) }
        }
    }

    override suspend fun getPlaylist(playlistId: Int): Playlist {
        val entity = playlistDao.getPlaylistById(playlistId)
            ?: throw Exception("Playlist not found: $playlistId")
        return mapEntityToDomain(entity)
    }

    override suspend fun downloadPlaylist(playlistId: Int): Result<Unit> {
        return try {
            Timber.tag("DWNLD").d("Starting download for playlist: $playlistId")

            // Update status to DOWNLOADING
            playlistDao.updateDownloadStatus(
                playlistId = playlistId,
                status = DownloadStatus.DOWNLOADING.name,
                downloadedItems = 0
            )

            val mediaList = mediaDao.getMediaByPlaylistId(playlistId)
            var downloadedCount = 0
            val missingFiles = mutableListOf<String>()

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

                    Timber.tag("DWNLD").d("URL: Downloading media: ${media.name} (${media.id})")

                    val localPath = mediaFileManager.downloadMedia(
                        url = media.file,
                        mediaId = media.id
                    ) { progress ->
                        // Update progress if needed
                        Timber.tag("DWNLD").v("Download progress for ${media.id}: $progress%")
                    }

                    if (localPath != null) {
                        // Verify checksum if available
                        val isValid = if (!media.checksum.isNullOrEmpty()) {
                            mediaFileManager.verifyChecksum(localPath, media.checksum)
                        } else {
                            true
                        }

                        if (true) {
                            mediaDao.markAsDownloaded(
                                mediaId = media.id,
                                localPath = localPath,
                                downloadedAt = System.currentTimeMillis()
                            )
                            downloadedCount++
                            Timber.d("Media downloaded successfully: ${media.name}")
                        } else {
                            Timber.tag("DWNLD").e("Checksum verification failed for media: ${media.name}")
                            missingFiles.add(media.name)
                        }
                    } else {
                        Timber.tag("DWNLD").e("Failed to download media: ${media.name}")
                        missingFiles.add(media.name)
                    }
                } catch (e: Exception) {
                    Timber.tag("DWNLD").e(e, "Error downloading media: ${media.name}")
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
                    downloadedItems = downloadedCount,
                    missingFiles = if (missingFiles.isNotEmpty()) {
                        gson.toJson(missingFiles)
                    } else null
                )
                playlistDao.updatePlaylist(updatedPlaylist)
            }

            Timber.tag("DWNLD").d("Playlist download completed: $downloadedCount/${mediaList.size} items")
            Result.success(Unit)
        } catch (e: Exception) {
            Timber.tag("DWNLD").e(e, "Failed to download playlist: $playlistId")

            // Update status to FAILED
            playlistDao.updateDownloadStatus(
                playlistId = playlistId,
                status = DownloadStatus.FAILED.name,
                downloadedItems = 0
            )

            Result.failure(e)
        }
    }

    override suspend fun downloadRemainingPlaylistsInBackground() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Timber.d("Starting background download for remaining playlists")
                val playlists = playlistDao.getAllPlaylists()

                for (playlist in playlists) {
                    // Skip playlists that are already READY
                    if (playlist.downloadStatus == DownloadStatus.READY.name) {
                        continue
                    }

                    Timber.d("Background downloading playlist: ${playlist.name}")
                    downloadPlaylist(playlist.id)
                }

                Timber.d("Background playlist downloads completed")
            } catch (e: Exception) {
                Timber.e(e, "Error in background playlist download")
            }
        }
    }

    override suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>) {
        try {
            Timber.d("Cleaning up old playlists, keeping: $playlistIdsToKeep")

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

            Timber.d("Old playlists cleaned up successfully")
        } catch (e: Exception) {
            Timber.e(e, "Failed to cleanup old playlists")
        }
    }

    private suspend fun mapEntityToDomain(entity: PlaylistEntity): Playlist {
        val mediaEntities = mediaDao.getMediaByPlaylistId(entity.id)
        val mediaList = mediaEntities.map { mediaEntity ->
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
            downloadedItems = entity.downloadedItems,
            missingFiles = missingFilesList,
            lastSyncedAt = entity.lastSyncedAt
        )
    }
}
