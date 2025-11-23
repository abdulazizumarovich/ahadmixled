package uz.iportal.axadmixled.domain.repository

import kotlinx.coroutines.flow.Flow
import uz.iportal.axadmixled.domain.model.Playlist

interface PlaylistRepository {
    suspend fun syncPlaylists(forceRenew: Boolean = false): Result<Unit>
    suspend fun getActivePlaylist(): Playlist?
    suspend fun getPlaylists(): List<Playlist>
    fun getPlaylistsFlow(): Flow<List<Playlist>>
    suspend fun switchPlaylist(playlistId: Int): Playlist?
    suspend fun downloadPlaylist(playlistId: Int): Result<Unit>
    suspend fun downloadRemainingPlaylistsInBackground()
    suspend fun deactivatePlaylist(playlistId: Int)
    suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>)
}
