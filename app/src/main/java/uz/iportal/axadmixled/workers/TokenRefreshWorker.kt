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
            Timber.tag(TAG).d("Starting token refresh")

            if (!authRepository.isAuthenticated()) {
                Timber.tag(TAG).w("User not authenticated, skipping refresh")
                return Result.success()
            }

            authRepository.refreshTokenIfNeeded().fold(
                onSuccess = {
                    Timber.tag(TAG).d("Token refreshed successfully")
                    Result.success()
                },
                onFailure = { exception ->
                    Timber.tag(TAG).e(exception, "TokenRefreshWorker: Failed to refresh token")
                    Result.retry()
                }
            )
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Unexpected error")
            Result.retry()
        }
    }

    companion object {
        const val WORK_NAME = "token_refresh_work"
        const val TAG = "TokenRefreshWorker"
    }
}
