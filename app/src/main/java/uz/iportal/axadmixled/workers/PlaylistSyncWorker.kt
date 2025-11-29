package uz.iportal.axadmixled.workers

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import timber.log.Timber
import uz.iportal.axadmixled.domain.repository.AuthRepository
import uz.iportal.axadmixled.domain.repository.PlaylistRepository

/**
 * Background worker to sync playlists from server
 * Downloads new playlists and updates existing ones
 */
@HiltWorker
class PlaylistSyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val authRepository: AuthRepository,
    private val playlistRepository: PlaylistRepository
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            Timber.tag(TAG).d("Starting playlist sync")

            if (!authRepository.isAuthenticated()) {
                Timber.tag(TAG).w("User not authenticated, skipping sync")
                return Result.failure()
            }

            playlistRepository.syncPlaylists().fold(
                onSuccess = {
                    Timber.tag(TAG).d("Playlists synced successfully")

                    // Start background download for remaining playlists
                    playlistRepository.downloadRemainingPlaylistsInBackground()

                    Result.success()
                },
                onFailure = { exception ->
                    Timber.tag(TAG).e(exception, "Failed to sync playlists")
                    Result.retry()
                }
            )
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Unexpected error")
            Result.retry()
        }
    }

    companion object {
        const val TAG = "PlaylistSyncWorker"
        const val WORK_NAME = "playlist_sync_work"
    }
}
