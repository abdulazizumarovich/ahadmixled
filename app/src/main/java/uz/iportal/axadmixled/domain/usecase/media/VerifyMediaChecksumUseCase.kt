package uz.iportal.axadmixled.domain.usecase.media

import uz.iportal.axadmixled.domain.model.Media
import uz.iportal.axadmixled.domain.repository.MediaRepository
import javax.inject.Inject

class VerifyMediaChecksumUseCase @Inject constructor(
    private val mediaRepository: MediaRepository
) {
    suspend operator fun invoke(media: Media): Boolean {
        return mediaRepository.verifyMediaChecksum(media)
    }
}
