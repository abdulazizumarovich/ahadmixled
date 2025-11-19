package uz.iportal.axadmixled.domain.usecase.media

import uz.iportal.axadmixled.domain.model.Media
import uz.iportal.axadmixled.domain.repository.MediaRepository
import javax.inject.Inject

class DownloadMediaUseCase @Inject constructor(
    private val mediaRepository: MediaRepository
) {
    suspend operator fun invoke(
        media: Media,
        onProgress: (Int) -> Unit = {}
    ): Result<String> {
        return mediaRepository.downloadMedia(media, onProgress)
    }
}
