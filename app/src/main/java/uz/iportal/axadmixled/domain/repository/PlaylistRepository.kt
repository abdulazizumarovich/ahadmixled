package uz.iportal.axadmixled.domain.repository

import kotlinx.coroutines.flow.Flow
import uz.iportal.axadmixled.domain.model.Playlist

interface PlaylistRepository {
    suspend fun syncPlaylists(): Result<Unit>
    suspend fun getActivePlaylist(): Playlist?
    suspend fun getPlaylists(): List<Playlist>
    fun getPlaylistsFlow(): Flow<List<Playlist>>
    suspend fun getPlaylist(playlistId: Int): Playlist?
    suspend fun downloadPlaylist(playlistId: Int): Result<Unit>
    suspend fun downloadRemainingPlaylistsInBackground()
    suspend fun cleanupOldPlaylists(playlistIdsToKeep: List<Int>)
}
