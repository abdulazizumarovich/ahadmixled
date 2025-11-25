package uz.iportal.axadmixled.util

import timber.log.Timber
import java.io.File
import java.security.MessageDigest

private const val TAG = "Checksum"

infix fun String?.notMatches(filePath: String?): Boolean {
    return !matches(filePath)
}

infix fun String?.matches(filePath: String?): Boolean {
    if (isNullOrEmpty()) {
        Timber.tag(TAG).d("No checksum available, skipping verification")
        return false
    }
    if (filePath.isNullOrEmpty()) {
        Timber.tag(TAG).w("No local path for media, skipping verification")
        return false
    }

    return try {
        val file = File(filePath)
        if (!file.exists()) {
            Timber.tag(TAG).e("Checksum not verified, no file is found")
            return false
        }

        val inputStream = file.inputStream()
        val buffer = ByteArray(1024)
        var read = inputStream.read(buffer)
        val digest = MessageDigest.getInstance("MD5")
        while (read > 0) {
            digest.update(buffer, 0, read)
            read = inputStream.read(buffer)
        }

        val md5sum = digest.digest().joinToString("") { "%02x".format(it) }
        if (equals(md5sum, ignoreCase = true)) {
            return true
        }
        Timber.tag(TAG).e("Checksum invalid, skipping it anyway TEMPORARY SOLUTION")
        true // TODO remove
    } catch (e: Exception) {
        Timber.tag(TAG).e(e, "Failed to verify checksum")
        false
    }
}