package uz.iportal.axadmixled

import android.app.Application
import android.util.Log
import androidx.work.Configuration
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber
import uz.iportal.axadmixled.domain.repository.TimeRepository
import uz.iportal.axadmixled.util.FileLoggingTree
import uz.iportal.axadmixled.util.StorageMonitor
import uz.iportal.axadmixled.workers.LedPlayerWorkerFactory
import uz.iportal.axadmixled.workers.WorkManagerInitializer
import javax.inject.Inject

@HiltAndroidApp
class LedPlayerApplication : Application(), Configuration.Provider {

    @Inject
    lateinit var timeRepository: TimeRepository

    @Inject
    lateinit var storageMonitor: StorageMonitor

    @Inject
    lateinit var ledPlayerWorkerFactory: LedPlayerWorkerFactory

    private val workManagerInitializer = WorkManagerInitializer()

    override fun onCreate() {
        super.onCreate()
        timeRepository.initialize(this)

        // Initialize Timber for logging
        @Suppress("KotlinConstantConditions")
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(FileLoggingTree(this))
        }

        Timber.d("LedPlayerApplication started")

        // Start storage monitoring
        storageMonitor.startMonitoring()

        // Initialize WorkManager for background tasks
        workManagerInitializer.initialize(this)

        Timber.d("LedPlayerApplication initialization complete")
    }

    override fun onTerminate() {
        storageMonitor.stopMonitoring()
        workManagerInitializer.cancelAll()
        super.onTerminate()
    }

    @Suppress("KotlinConstantConditions")
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(ledPlayerWorkerFactory)
            .setMinimumLoggingLevel(if (BuildConfig.DEBUG) Log.DEBUG else Log.ERROR)
            .build()
}
