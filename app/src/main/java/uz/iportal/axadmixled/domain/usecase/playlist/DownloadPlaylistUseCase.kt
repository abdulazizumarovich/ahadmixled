package uz.iportal.axadmixled.domain.usecase.playlist

import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import javax.inject.Inject

class DownloadPlaylistUseCase @Inject constructor(
    private val playlistRepository: PlaylistRepository
) {
    suspend operator fun invoke(playlistId: Int): Result<Unit> {
        return playlistRepository.downloadPlaylist(playlistId)
    }
}
