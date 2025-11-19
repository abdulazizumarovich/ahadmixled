package uz.iportal.axadmixled.workers

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import timber.log.Timber
import uz.iportal.axadmixled.domain.repository.AuthRepository

/**
 * Background worker to refresh authentication tokens periodically
 * Runs every 23 hours to ensure token is always fresh
 */
@HiltWorker
class TokenRefreshWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val authRepository: AuthRepository
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            Timber.d("TokenRefreshWorker: Starting token refresh")

            if (!authRepository.isAuthenticated()) {
                Timber.w("TokenRefreshWorker: User not authenticated, skipping refresh")
                return Result.success()
            }

            val result = authRepository.refreshTokenIfNeeded()

            result.fold(
                onSuccess = {
                    Timber.d("TokenRefreshWorker: Token refreshed successfully")
                    Result.success()
                },
                onFailure = { exception ->
                    Timber.e(exception, "TokenRefreshWorker: Failed to refresh token")
                    Result.retry()
                }
            )
        } catch (e: Exception) {
            Timber.e(e, "TokenRefreshWorker: Unexpected error")
            Result.retry()
        }
    }

    companion object {
        const val WORK_NAME = "token_refresh_work"
    }
}
