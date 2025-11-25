package uz.iportal.axadmixled.data.local.storage

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CancellationException
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MediaFileManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val okHttpClient: OkHttpClient
) {
    private val mediaDir = File(context.getExternalFilesDir(null), "media")

    init {
        mediaDir.mkdirs()
    }

    fun getMediaDirectory(): File = mediaDir

    fun getOrCreatePlaylistDirectory(playlistId: Int): File {
        return File(mediaDir, playlistId.toString()).also {
            it.mkdirs()
        }
    }

    fun downloadMedia(
        url: String,
        mediaId: Int,
        playlistId: Int,
        onProgress: (progress: Int) -> Unit = {}
    ): String? {
        try {
            val fileName = url.substringAfterLast("/")
            val file = File(getOrCreatePlaylistDirectory(playlistId), "${mediaId}_$fileName")

            if (file.exists()) {
                Timber.tag(TAG).d("File already exists: ${file.absolutePath}")
                return file.absolutePath
            }

            val request = Request.Builder().url(url).build()
            val response = okHttpClient.newCall(request).execute()

            if (!response.isSuccessful) {
                Timber.tag(TAG).e("Download failed with code: ${response.code}")
                return null
            }

            val body = response.body ?: return null
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
            return file.absolutePath
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to download media")
            return null
        }
    }

    fun getMediaPath(mediaId: Int, playlistId: Int): String? {
        return getOrCreatePlaylistDirectory(playlistId).listFiles()
            ?.firstOrNull { it.name.startsWith("${mediaId}_") }
            ?.absolutePath
    }

    fun cleanPlaylistFolders(keepPlaylists: List<Int>) {
        try {
            mediaDir.listFiles()
                ?.filter { it.isDirectory && !keepPlaylists.contains(it.name.toInt()) }
                ?.forEach { it.deleteRecursively() }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to delete media file")
        }
    }

    companion object {
        private const val TAG = "MediaFileManager"
    }
}
