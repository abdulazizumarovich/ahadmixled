package uz.iportal.axadmixled.data.local.database.dao

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import uz.iportal.axadmixled.data.local.database.entities.PlaylistEntity

@Dao
interface PlaylistDao {
    @Query("SELECT * FROM playlists ORDER BY priority DESC")
    fun getAllPlaylistsFlow(): Flow<List<PlaylistEntity>>

    @Query("SELECT * FROM playlists ORDER BY priority DESC")
    suspend fun getAllPlaylists(): List<PlaylistEntity>

    @Query("SELECT * FROM playlists WHERE id = :playlistId")
    suspend fun getPlaylistById(playlistId: Int): PlaylistEntity?

    @Query("SELECT * FROM playlists WHERE is_active = 1 LIMIT 1")
    suspend fun getActivePlaylist(): PlaylistEntity?

    @Query("SELECT id FROM playlists")
    suspend fun getReadyPlaylistIds(): List<Int>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylist(playlist: PlaylistEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylists(playlists: List<PlaylistEntity>)

    @Update
    suspend fun updatePlaylist(playlist: PlaylistEntity)

    @Query("UPDATE playlists SET download_status = :status, downloaded_items = :downloadedItems WHERE id = :playlistId")
    suspend fun updateDownloadStatus(playlistId: Int, status: String, downloadedItems: Int)

    @Query("DELETE FROM playlists WHERE id = :playlistId")
    suspend fun deletePlaylist(playlistId: Int)

    @Query("DELETE FROM playlists WHERE id NOT IN (:playlistIds)")
    suspend fun deletePlaylistsNotIn(playlistIds: List<Int>)
}
