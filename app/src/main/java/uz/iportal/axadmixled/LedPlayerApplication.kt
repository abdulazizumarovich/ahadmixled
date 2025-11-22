package uz.iportal.axadmixled

import android.app.Application
import androidx.work.Configuration
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber
import uz.iportal.axadmixled.util.StorageMonitor
import uz.iportal.axadmixled.workers.LedPlayerWorkerFactory
import uz.iportal.axadmixled.workers.WorkManagerInitializer
import javax.inject.Inject

@HiltAndroidApp
class LedPlayerApplication : Application(), Configuration.Provider {

    @Inject
    lateinit var storageMonitor: StorageMonitor

    @Inject
    lateinit var ledPlayerWorkerFactory: LedPlayerWorkerFactory

    private val workManagerInitializer = WorkManagerInitializer()

    override fun onCreate() {
        super.onCreate()

        // Initialize Timber for logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            // In production, you might want to use a custom tree
            // that logs to a file or remote service
            Timber.plant(object : Timber.Tree() {
                override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
                    // Log to file or remote service
                }
            })
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

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(ledPlayerWorkerFactory)
            .setMinimumLoggingLevel(if (BuildConfig.DEBUG) android.util.Log.DEBUG else android.util.Log.ERROR)
            .build()
}
