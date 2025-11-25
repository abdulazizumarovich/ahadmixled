package uz.iportal.axadmixled.data.local.database.dao

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import uz.iportal.axadmixled.data.local.database.entities.MediaEntity

@Dao
interface MediaDao {
    @Query("SELECT * FROM media WHERE playlist_id = :playlistId ORDER BY `order` ASC")
    fun getMediaByPlaylistIdFlow(playlistId: Int): Flow<List<MediaEntity>>

    @Query("SELECT * FROM media WHERE playlist_id = :playlistId ORDER BY `order` ASC")
    suspend fun getMediaByPlaylistId(playlistId: Int): List<MediaEntity>

    @Query("SELECT * FROM media WHERE id = :mediaId")
    suspend fun getMediaById(mediaId: Int): MediaEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMedia(media: MediaEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMediaList(mediaList: List<MediaEntity>)

    @Update
    suspend fun updateMedia(media: MediaEntity)

    @Query("UPDATE media SET is_downloaded = 1, local_path = :localPath, downloaded_at = :downloadedAt WHERE id = :mediaId")
    suspend fun markAsDownloaded(mediaId: Int, localPath: String, downloadedAt: Long)

    @Query("DELETE FROM media WHERE playlist_id = :playlistId")
    suspend fun deleteMediaByPlaylistId(playlistId: Int)

    @Query("DELETE FROM media WHERE playlist_id NOT IN (:playlistIds)")
    suspend fun cleanOtherThanGivenPlaylists(playlistIds: List<Int>)
}
