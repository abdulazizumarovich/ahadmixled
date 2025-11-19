package uz.iportal.axadmixled.domain.usecase.device

import uz.iportal.axadmixled.domain.model.DeviceRegisterResponse
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import javax.inject.Inject

class RegisterDeviceUseCase @Inject constructor(
    private val deviceRepository: DeviceRepository
) {
    suspend operator fun invoke(): Result<DeviceRegisterResponse> {
        return deviceRepository.registerDevice()
    }
}
