package uz.iportal.axadmixled.di

import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import uz.iportal.axadmixled.data.repository.AuthRepositoryImpl
import uz.iportal.axadmixled.data.repository.DeviceRepositoryImpl
import uz.iportal.axadmixled.data.repository.PlaylistRepositoryImpl
import uz.iportal.axadmixled.data.repository.ScreenshotRepositoryImpl
import uz.iportal.axadmixled.data.repository.TimeRepositoryImpl
import uz.iportal.axadmixled.domain.repository.AuthRepository
import uz.iportal.axadmixled.domain.repository.DeviceRepository
import uz.iportal.axadmixled.domain.repository.PlaylistRepository
import uz.iportal.axadmixled.domain.repository.ScreenshotRepository
import uz.iportal.axadmixled.domain.repository.TimeRepository
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(
        authRepositoryImpl: AuthRepositoryImpl
    ): AuthRepository

    @Binds
    @Singleton
    abstract fun bindDeviceRepository(
        deviceRepositoryImpl: DeviceRepositoryImpl
    ): DeviceRepository

    @Binds
    @Singleton
    abstract fun bindPlaylistRepository(
        playlistRepositoryImpl: PlaylistRepositoryImpl
    ): PlaylistRepository

    @Binds
    @Singleton
    abstract fun bindScreenshotRepository(
        screenshotRepositoryImpl: ScreenshotRepositoryImpl
    ): ScreenshotRepository

    @Binds
    @Singleton
    abstract fun bindTimeRepository(
        timeRepositoryImpl: TimeRepositoryImpl
    ): TimeRepository
}
