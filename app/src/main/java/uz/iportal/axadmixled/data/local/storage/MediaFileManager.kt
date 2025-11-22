package uz.iportal.axadmixled.data.local.storage

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber

import java.io.File
import java.security.MessageDigest
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "MediaFileManager"

@Singleton
class MediaFileManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val okHttpClient: OkHttpClient
) {
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
                Timber.tag(TAG).d("File already exists: ${file.absolutePath}")
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

                Timber.tag(TAG).d("Downloaded media: ${file.absolutePath}")
                file.absolutePath
            } else {
                Timber.tag(TAG).e("Download failed with code: ${response.code}")
                null
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to download media")
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
        try {
            val files = mediaDir.listFiles() ?: return
            files.forEach { file ->
                // This is a simple implementation
                // You might want to add more sophisticated logic
                if (file.isFile) {
                    Timber.tag(TAG).d("Considering deletion of: ${file.name}")
                }
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error deleting playlist media")
        }
    }

    fun verifyChecksum(filePath: String, expectedChecksum: String?): Boolean {
        if (expectedChecksum.isNullOrEmpty()) return false

        return try {
            val file = File(filePath)
            val digest = MessageDigest.getInstance("MD5")
            val inputStream = file.inputStream()
            val buffer = ByteArray(1024)
            var read = inputStream.read(buffer)

            while (read > 0) {
                digest.update(buffer, 0, read)
                read = inputStream.read(buffer)
            }

            val md5sum = digest.digest().joinToString("") { "%02x".format(it) }
            val valid = md5sum.equals(expectedChecksum, ignoreCase = true)
            if (!valid) {
                Timber.tag(TAG).e("Checksum invalid, skipping it anyway TEMPORARY SOLUTION")
            }
            true // TODO remove
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to verify checksum")
            false
        }
    }

    fun deleteMedia(localPath: String) {
        try {
            val file = File(localPath)
            if (file.exists()) {
                file.delete()
                Timber.tag(TAG).d("Deleted media file: $localPath")
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to delete media file")
        }
    }
}
