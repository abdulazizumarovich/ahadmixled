package uz.iportal.axadmixled.di

import android.content.Context
import androidx.room.Room
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import uz.iportal.axadmixled.data.local.database.AppDatabase
import uz.iportal.axadmixled.data.local.database.dao.DeviceDao
import uz.iportal.axadmixled.data.local.database.dao.MediaDao
import uz.iportal.axadmixled.data.local.database.dao.PlaylistDao
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "led_player_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    @Singleton
    fun providePlaylistDao(database: AppDatabase): PlaylistDao {
        return database.playlistDao()
    }

    @Provides
    @Singleton
    fun provideMediaDao(database: AppDatabase): MediaDao {
        return database.mediaDao()
    }

    @Provides
    @Singleton
    fun provideDeviceDao(database: AppDatabase): DeviceDao {
        return database.deviceDao()
    }
}
