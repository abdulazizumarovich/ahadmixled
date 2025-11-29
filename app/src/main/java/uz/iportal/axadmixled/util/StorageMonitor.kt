package uz.iportal.axadmixled.util

import android.os.StatFs
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.data.local.storage.MediaFileManager
import uz.iportal.axadmixled.domain.model.StorageInfo
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StorageMonitor @Inject constructor(
    private val mediaFileManager: MediaFileManager
) {
    private val _storageUpdates = MutableSharedFlow<StorageInfo>(replay = 1)
    val storageUpdates: SharedFlow<StorageInfo> = _storageUpdates.asSharedFlow()

    private val storageCheckInterval = Constants.STORAGE_CHECK_INTERVAL
    private var monitorJob: Job? = null

    fun startMonitoring() {
        if (monitorJob?.isActive == true) return

        monitorJob = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                try {
                    val storageInfo = getStorageInfo()
                    _storageUpdates.emit(storageInfo)
                    delay(storageCheckInterval)
                } catch (e: Exception) {
                    Timber.e(e, "Error monitoring storage")
                }
            }
        }
    }

    fun stopMonitoring() {
        monitorJob?.cancel()
        monitorJob = null
    }

    fun getStorageInfo(): StorageInfo {
        val mediaDir = mediaFileManager.getMediaDirectory()
        val stat = StatFs(mediaDir.path)

        val totalSpace = stat.totalBytes
        val freeSpace = stat.availableBytes
        val usedSpace = totalSpace - freeSpace

        return StorageInfo(
            totalSpace = totalSpace,
            freeSpace = freeSpace,
            usedSpace = usedSpace,
            usedByApp = calculateAppStorage()
        )
    }

    private fun calculateAppStorage(): Long {
        return try {
            val mediaDir = mediaFileManager.getMediaDirectory()
            mediaDir.walkTopDown()
                .filter { it.isFile }
                .map { it.length() }
                .sum()
        } catch (e: Exception) {
            Timber.e(e, "Error calculating app storage")
            0L
        }
    }
}
