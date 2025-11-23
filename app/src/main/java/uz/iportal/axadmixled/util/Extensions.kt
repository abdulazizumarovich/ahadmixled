package uz.iportal.axadmixled.util

import android.net.Uri
import java.io.File

fun String?.localPathToUri(): Uri? {
    if (this.isNullOrEmpty()) return null
    val file = File(this)
    if (!file.exists()) return null
    return Uri.fromFile(file)
}

fun Map<String, Any>?.getInt(key: String, default: Int? = null): Int? {
    return getAs<Double>(key, default?.toDouble())?.toInt()
}

fun Map<String, Any>?.getLong(key: String, default: Long? = null): Long? {
    return getAs<Double>(key, default?.toDouble())?.toLong()
}

inline fun <reified T> Map<String, Any>?.getAs(key: String, default: T? = null): T? {
    this?.get(key)?.let {
        check(it is T) { "Expected param type: ${T::class.java.name}, but found: ${it.javaClass.name}" }
        return it
    }

    return default
}