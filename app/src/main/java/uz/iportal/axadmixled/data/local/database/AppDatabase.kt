package uz.iportal.axadmixled.data.local.database

import androidx.room.Database
import androidx.room.RoomDatabase
import uz.iportal.axadmixled.data.local.database.dao.DeviceDao
import uz.iportal.axadmixled.data.local.database.dao.MediaDao
import uz.iportal.axadmixled.data.local.database.dao.PlaylistDao
import uz.iportal.axadmixled.data.local.database.entities.DeviceEntity
import uz.iportal.axadmixled.data.local.database.entities.MediaEntity
import uz.iportal.axadmixled.data.local.database.entities.PlaylistEntity

@Database(
    entities = [
        PlaylistEntity::class,
        MediaEntity::class,
        DeviceEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun playlistDao(): PlaylistDao
    abstract fun mediaDao(): MediaDao
    abstract fun deviceDao(): DeviceDao
}
