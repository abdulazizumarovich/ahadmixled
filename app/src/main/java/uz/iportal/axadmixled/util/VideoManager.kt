package uz.iportal.axadmixled.util

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber
import java.io.File

class VideoManager(private val context: Context) {

    private val okHttpClient = OkHttpClient()
    private val videoDir = File(context.getExternalFilesDir(null), "videos").apply {
        if (!exists()) mkdirs()
    }

    /**
     * Download video from URL and save locally
     * @param url Video URL to download
     * @param videoId Unique identifier for the video
     * @param onProgress Progress callback (0-100)
     * @return Absolute path to downloaded file or null if failed
     */
    suspend fun downloadVideo(
        url: String,
        videoId: Int,
        onProgress: (progress: Int) -> Unit = {}
    ): String? = withContext(Dispatchers.IO) {
        try {
            val fileName = url.substringAfterLast("/")
            val file = File(videoDir, "${videoId}_$fileName")

            // Return cached file if it exists
            if (file.exists()) {
                Timber.d("Video already exists: ${file.absolutePath}")
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

                Timber.d("Downloaded video: ${file.absolutePath}")
                file.absolutePath
            } else {
                Timber.e("Download failed with code: ${response.code}")
                null
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to download video")
            null
        }
    }

    /**
     * Get video file by title/filename
     * @param title Video title (e.g., "default_video")
     * @return File object if found, null otherwise
     */
    fun getVideoByTitle(title: String): File? {
        val files = videoDir.listFiles() ?: return null

        // Search for file containing the title
        val foundFile = files.find { file ->
            file.name.contains(title, ignoreCase = true)
        }

        return if (foundFile?.exists() == true) {
            Timber.d("Found video: ${foundFile.absolutePath}")
            foundFile
        } else {
            Timber.w("Video not found: $title")
            null
        }
    }

    /**
     * Get video file path by title
     * @param title Video title
     * @return Absolute path if found, null otherwise
     */
    fun getVideoPathByTitle(title: String): String? {
        return getVideoByTitle(title)?.absolutePath
    }
}