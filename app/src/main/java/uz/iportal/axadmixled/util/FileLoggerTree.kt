package uz.iportal.axadmixled.util

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import timber.log.Timber
import uz.iportal.axadmixled.BuildConfig
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FileLoggingTree(private val context: Context) : Timber.Tree() {

    init {
        if (hasStoragePermission()) {
            val logsDir = getLogsDir()
            if (!logsDir.exists()) {
                logsDir.mkdirs()
            } else repeat(3) {
                writeToFile(System.lineSeparator())
            }

            cleanOldFiles()
            shrinkIfNeeded()
            printInfo()
        }
    }

    private fun printInfo() {
        writeToFile(SEPARATOR_LINE + System.lineSeparator())
        writeToFile("APPLICATION V${BuildConfig.VERSION_NAME}(${BuildConfig.VERSION_CODE}) variant: ${BuildConfig.FLAVOR}")
        writeToFile(System.lineSeparator())
        writeToFile(SEPARATOR_LINE + System.lineSeparator())
        writeToFile(System.lineSeparator())
    }

    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        if (!hasStoragePermission()) return

        val level = priority.toLogLevel()
        val body = message + (t?.let { "\n${Log.getStackTraceString(it)}" } ?: "")
        val timestamp = SimpleDateFormat(TIME_FORMAT, Locale.ENGLISH).format(Date())
        val logText = "$timestamp $level/${tag ?: "no-tag"}: $body\n"

        writeToFile(logText)
    }

    private fun hasStoragePermission() = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    ) == PackageManager.PERMISSION_GRANTED

    private fun Int.toLogLevel() = when (this) {
        Log.VERBOSE -> "V"
        Log.DEBUG -> "D"
        Log.INFO -> "I"
        Log.WARN -> "W"
        Log.ERROR -> "E"
        Log.ASSERT -> "A"
        else -> "?"
    }

    private fun writeToFile(text: String) {
        runCatching {
            getFile().appendText(text)
        }.onFailure { it.printStackTrace() }
    }

    private fun getFile() = File(
        context.getExternalFilesDir(null),
        "logs/log-${SimpleDateFormat(DATE_FORMAT, Locale.ENGLISH).format(Date())}.txt"
    )

    private fun shrinkIfNeeded() {
        val file = getFile()
        if (!file.exists() || file.length() <= MAX_SIZE) return

        val newLines = file.readLines().takeLast(KEEP_LINES)
        file.writeText(newLines.joinToString("\n"))
    }

    private fun cleanOldFiles() {
        val cutoff = System.currentTimeMillis() - DAYS_TO_KEEP * MS_IN_DAY
        getLogsDir().listFiles()?.forEach { file ->
            if (file.isFile && file.lastModified() < cutoff) {
                runCatching { file.delete() }
            }
        }
    }

    private fun getLogsDir(): File = File(context.getExternalFilesDir(null), "logs")

    companion object {
        private const val SEPARATOR_LINE = "==============================================="
        private const val DATE_FORMAT = "yyyy-MM-dd"
        private const val TIME_FORMAT = "yyyy-MM-dd HH:mm:ss.SSS"
        private const val MS_IN_DAY = 24L * 60L * 60L * 1000L
        private const val DAYS_TO_KEEP = 3
        private const val KEEP_LINES = 5000
        private const val MAX_SIZE = 5 * 1024 * 1024 // 5MB
    }
}