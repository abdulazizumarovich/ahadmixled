package uz.iportal.axadmixled.domain.repository

import uz.iportal.axadmixled.domain.model.Media

interface MediaRepository {
    suspend fun downloadMedia(media: Media, onProgress: (Int) -> Unit = {}): Result<String>
    suspend fun getMediaByPlaylistId(playlistId: Int): List<Media>
    suspend fun verifyMediaChecksum(media: Media): Boolean
}
