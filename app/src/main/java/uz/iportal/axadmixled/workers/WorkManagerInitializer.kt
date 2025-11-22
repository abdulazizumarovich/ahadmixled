package uz.iportal.axadmixled.workers

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkRequest
import timber.log.Timber
import java.util.concurrent.TimeUnit

/**
 * Initializes and schedules all background workers
 */
class WorkManagerInitializer() {
    private lateinit var workManager: WorkManager

    /**
     * Initialize all periodic workers
     */
    fun initialize(context: Context) {
        Timber.d("Creating WorkManager instance")
        workManager = WorkManager.getInstance(context)
        Timber.d("WorkManagerInitializer: Scheduling periodic workers")
        scheduleTokenRefresh()
        schedulePlaylistSync()
    }

    /**
     * Schedule token refresh worker to run every 23 hours
     */
    private fun scheduleTokenRefresh() {
        if (!::workManager.isInitialized) return

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val tokenRefreshRequest = PeriodicWorkRequestBuilder<TokenRefreshWorker>(
            23, TimeUnit.HOURS,
            15, TimeUnit.MINUTES // Flex interval
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

        workManager.enqueueUniquePeriodicWork(
            TokenRefreshWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            tokenRefreshRequest
        )

        Timber.d("WorkManagerInitializer: Token refresh worker scheduled")
    }

    /**
     * Schedule playlist sync worker to run every 6 hours
     */
    private fun schedulePlaylistSync() {
        if (!::workManager.isInitialized) return

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val playlistSyncRequest = PeriodicWorkRequestBuilder<PlaylistSyncWorker>(
            6, TimeUnit.HOURS,
            15, TimeUnit.MINUTES // Flex interval
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

        workManager.enqueueUniquePeriodicWork(
            PlaylistSyncWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            playlistSyncRequest
        )

        Timber.d("WorkManagerInitializer: Playlist sync worker scheduled")
    }

    /**
     * Cancel all workers
     */
    fun cancelAll() {
        if (!::workManager.isInitialized) return

        workManager.cancelUniqueWork(TokenRefreshWorker.WORK_NAME)
        workManager.cancelUniqueWork(PlaylistSyncWorker.WORK_NAME)
        Timber.d("WorkManagerInitializer: All workers cancelled")
    }
}
