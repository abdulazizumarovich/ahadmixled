package uz.iportal.axadmixled.util

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.widget.Toast
import androidx.annotation.StringRes
import java.text.SimpleDateFormat
import java.util.*

/**
 * Extension functions for the Android LED Player application
 */

// Context Extensions
fun Context.isNetworkAvailable(): Boolean {
    val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    } else {
        @Suppress("DEPRECATION")
        val networkInfo = connectivityManager.activeNetworkInfo
        @Suppress("DEPRECATION")
        return networkInfo?.isConnected == true
    }
}

fun Context.showToast(message: String, duration: Int = Toast.LENGTH_SHORT) {
    Toast.makeText(this, message, duration).show()
}

fun Context.showToast(@StringRes messageRes: Int, duration: Int = Toast.LENGTH_SHORT) {
    Toast.makeText(this, messageRes, duration).show()
}

// String Extensions
fun String.toMd5(): String {
    val md = java.security.MessageDigest.getInstance("MD5")
    val digest = md.digest(this.toByteArray())
    return digest.joinToString("") { "%02x".format(it) }
}

fun String.isValidUrl(): Boolean {
    return android.util.Patterns.WEB_URL.matcher(this).matches()
}

// Long Extensions (for file sizes)
fun Long.toReadableFileSize(): String {
    if (this <= 0) return "0 B"
    val units = arrayOf("B", "KB", "MB", "GB", "TB")
    val digitGroups = (Math.log10(this.toDouble()) / Math.log10(1024.0)).toInt()
    return String.format("%.2f %s", this / Math.pow(1024.0, digitGroups.toDouble()), units[digitGroups])
}

// Date Extensions
fun Long.toFormattedDate(pattern: String = "dd MMM yyyy HH:mm"): String {
    val sdf = SimpleDateFormat(pattern, Locale.getDefault())
    return sdf.format(Date(this))
}

fun String.parseDate(pattern: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"): Date? {
    return try {
        val sdf = SimpleDateFormat(pattern, Locale.getDefault())
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        sdf.parse(this)
    } catch (e: Exception) {
        null
    }
}

// Int Extensions (for percentages)
fun Int.toPercentage(): String = "$this%"

fun Float.toPercentage(): String = "${this.toInt()}%"

// Collection Extensions
fun <T> List<T>.safeSubList(fromIndex: Int, toIndex: Int): List<T> {
    if (isEmpty()) return emptyList()
    val safeFrom = fromIndex.coerceAtLeast(0)
    val safeTo = toIndex.coerceAtMost(size)
    return if (safeFrom >= safeTo) emptyList() else subList(safeFrom, safeTo)
}

// Device Info Extensions
fun Context.getDeviceModel(): String {
    return "${Build.MANUFACTURER} ${Build.MODEL}"
}

fun Context.getAndroidVersion(): String {
    return "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
}

fun Context.getScreenResolution(): String {
    val displayMetrics = resources.displayMetrics
    return "${displayMetrics.widthPixels}x${displayMetrics.heightPixels}"
}

// Storage Extensions
fun Long.toGB(): Double {
    return this / (1024.0 * 1024.0 * 1024.0)
}

fun Long.toMB(): Double {
    return this / (1024.0 * 1024.0)
}

// Result Extensions
fun <T> Result<T>.getOrLog(defaultValue: T, tag: String = "Result"): T {
    return getOrElse { exception ->
        timber.log.Timber.e(exception, "[$tag] Error getting result")
        defaultValue
    }
}

fun <T> Result<T>.onSuccessLog(tag: String = "Result", action: (T) -> Unit): Result<T> {
    onSuccess {
        timber.log.Timber.d("[$tag] Success: $it")
        action(it)
    }
    return this
}

fun <T> Result<T>.onFailureLog(tag: String = "Result", action: (Throwable) -> Unit = {}): Result<T> {
    onFailure {
        timber.log.Timber.e(it, "[$tag] Failure")
        action(it)
    }
    return this
}
