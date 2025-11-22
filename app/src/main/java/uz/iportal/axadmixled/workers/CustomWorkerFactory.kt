package uz.iportal.axadmixled.workers

import android.content.Context
import androidx.work.ListenableWorker
import androidx.work.WorkerFactory
import androidx.work.WorkerParameters
import uz.iportal.axadmixled.domain.repository.AuthRepository
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LedPlayerWorkerFactory @Inject constructor(
    private val authRepository: AuthRepository,
    private val playlistRepository: PlaylistRepository
) : WorkerFactory() {
    override fun createWorker(
        appContext: Context,
        workerClassName: String,
        workerParameters: WorkerParameters
    ): ListenableWorker? {
        return when (workerClassName) {
            PlaylistSyncWorker::class.java.name -> PlaylistSyncWorker(
                appContext,
                workerParameters,
                authRepository,
                playlistRepository
            )

            TokenRefreshWorker::class.java.name -> TokenRefreshWorker(
                appContext,
                workerParameters,
                authRepository
            )

            else -> null
        }
    }
}