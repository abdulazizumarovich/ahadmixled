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

    @Query("SELECT download_status FROM playlists WHERE id = :playlistId")
    suspend fun getDownloadStatusById(playlistId: Int): String?

    @Query("SELECT last_synced_at FROM playlists ORDER BY last_synced_at ASC limit 1")
    suspend fun getOldestSyncTime(): Long?

    @Query("SELECT * FROM playlists WHERE is_active = 1 ORDER BY priority DESC LIMIT 1")
    suspend fun getActivePlaylist(): PlaylistEntity?

    /**
     * Prioritizes a single row and all others will be deprioritized
     */
    @Query("""
        UPDATE playlists 
        SET priority = CASE 
            WHEN id = :playlistId THEN :priority 
            ELSE id 
        END
    """)
    suspend fun prioritize(playlistId: Int, priority: Int)

    @Query("SELECT id FROM playlists")
    suspend fun getReadyPlaylistIds(): List<Int>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylist(playlist: PlaylistEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylists(playlists: List<PlaylistEntity>)

    @Update
    suspend fun updatePlaylist(playlist: PlaylistEntity)

    @Query("UPDATE playlists SET download_status = :status WHERE id = :playlistId")
    suspend fun updateDownloadStatus(playlistId: Int, status: String)

    @Query("DELETE FROM playlists WHERE id = :playlistId")
    suspend fun deletePlaylist(playlistId: Int)

    @Query("DELETE FROM playlists WHERE id NOT IN (:playlistIds)")
    suspend fun deletePlaylistsNotIn(playlistIds: List<Int>)
}
