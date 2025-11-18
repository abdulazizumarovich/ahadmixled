package uz.iportal.axadmixled.util

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.view.View
import androidx.core.view.drawToBitmap
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ScreenshotCapture @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val screenshotDir = File(context.getExternalFilesDir(null), "screenshots")

    init {
        screenshotDir.mkdirs()
    }

    fun captureScreen(activity: Activity): File? {
        return try {
            val rootView = activity.window.decorView.rootView
            val bitmap = rootView.drawToBitmap()

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

    fun captureView(view: View): File? {
        return try {
            val bitmap = view.drawToBitmap()

            val timestamp = System.currentTimeMillis()
            val fileName = "screenshot_$timestamp.jpg"
            val file = File(screenshotDir, fileName)

            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            }

            bitmap.recycle()
            Timber.d("View screenshot captured: ${file.absolutePath}")
            file
        } catch (e: Exception) {
            Timber.e(e, "Failed to capture view screenshot")
            null
        }
    }

    fun deleteScreenshot(file: File) {
        try {
            if (file.exists()) {
                file.delete()
                Timber.d("Deleted screenshot: ${file.absolutePath}")
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to delete screenshot")
        }
    }
}
