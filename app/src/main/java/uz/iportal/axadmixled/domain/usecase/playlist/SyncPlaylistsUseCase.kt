package uz.iportal.axadmixled.domain.usecase.playlist

import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import javax.inject.Inject

class SyncPlaylistsUseCase @Inject constructor(
    private val playlistRepository: PlaylistRepository
) {
    suspend operator fun invoke(): Result<Unit> {
        return playlistRepository.syncPlaylists()
    }
}
