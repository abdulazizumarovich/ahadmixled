package uz.iportal.axadmixled.data.repository

import timber.log.Timber

import uz.iportal.axadmixled.data.local.database.dao.MediaDao
import uz.iportal.axadmixled.data.local.storage.MediaFileManager
import uz.iportal.axadmixled.domain.model.Media
import uz.iportal.axadmixled.domain.model.MediaType
import uz.iportal.axadmixled.domain.repository.MediaRepository
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "MediaRepository"

@Singleton
class MediaRepositoryImpl @Inject constructor(
    private val mediaDao: MediaDao,
    private val mediaFileManager: MediaFileManager
) : MediaRepository {

    override suspend fun downloadMedia(media: Media, onProgress: (Int) -> Unit): Result<String> {
        return try {
            Timber.tag(TAG).d("Downloading media: ${media.name} (ID: ${media.id})")

            // Check if already downloaded
            if (media.isDownloaded && !media.localPath.isNullOrEmpty()) {
                val file = java.io.File(media.localPath)
                if (file.exists()) {
                    Timber.tag(TAG).d("Media already exists: ${media.localPath}")
                    return Result.success(media.localPath)
                }
            }

            val localPath = mediaFileManager.downloadMedia(
                url = media.file,
                mediaId = media.id,
                onProgress = onProgress
            )

            if (localPath.isNullOrEmpty()) {
                Timber.tag(TAG).e("Failed to download media: ${media.name}")
                return Result.failure(Exception("Download failed"))
            }

            // Verify checksum if available
            val isValid = if (!media.checksum.isNullOrEmpty()) {
                val verified = mediaFileManager.verifyChecksum(localPath, media.checksum)
                if (!verified) {
                    Timber.tag(TAG).e("Checksum verification failed for: ${media.name}")
                    // Delete invalid file
                    mediaFileManager.deleteMedia(localPath)
                    return Result.failure(Exception("Checksum verification failed"))
                }
                verified
            } else {
                true
            }

            if (isValid) {
                // Update database
                mediaDao.markAsDownloaded(
                    mediaId = media.id,
                    localPath = localPath,
                    downloadedAt = System.currentTimeMillis()
                )

                Timber.tag(TAG).d("Media downloaded and verified successfully: ${media.name}")
                Result.success(localPath)
            } else {
                Result.failure(Exception("Media validation failed"))
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error downloading media: ${media.name}")
            Result.failure(e)
        }
    }

    override suspend fun getMediaByPlaylistId(playlistId: Int): List<Media> {
        return try {
            val mediaEntities = mediaDao.getMediaByPlaylistId(playlistId)
            mediaEntities.map { entity ->
                Media(
                    id = entity.id,
                    name = entity.name,
                    description = entity.description,
                    file = entity.file,
                    thumbnail = entity.thumbnail,
                    mediaType = MediaType.fromString(entity.mediaType),
                    duration = entity.duration,
                    fileSize = entity.fileSize,
                    resolution = entity.resolution,
                    checksum = entity.checksum,
                    order = entity.order,
                    createdAt = entity.createdAt,
                    updatedAt = entity.updatedAt,
                    localPath = entity.localPath,
                    isDownloaded = entity.isDownloaded,
                    downloadedAt = entity.downloadedAt,
                    downloadProgress = entity.downloadProgress
                )
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to get media for playlist: $playlistId")
            emptyList()
        }
    }

    override suspend fun verifyMediaChecksum(media: Media): Boolean {
        return try {
            if (media.localPath.isNullOrEmpty()) {
                Timber.tag(TAG).w("No local path for media: ${media.name}")
                return false
            }

            if (media.checksum.isNullOrEmpty()) {
                Timber.tag(TAG).d("No checksum available for media: ${media.name}, skipping verification")
                return true
            }

            val isValid = mediaFileManager.verifyChecksum(media.localPath, media.checksum)

            if (isValid) {
                Timber.tag(TAG).d("Checksum verified successfully for: ${media.name}")
            } else {
                Timber.tag(TAG).e("Checksum verification failed for: ${media.name}")
            }

            isValid
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error verifying checksum for media: ${media.name}")
            false
        }
    }
}
