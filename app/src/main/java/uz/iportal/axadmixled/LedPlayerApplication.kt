package uz.iportal.axadmixled

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber
import uz.iportal.axadmixled.util.StorageMonitor
import javax.inject.Inject

@HiltAndroidApp
class LedPlayerApplication : Application() {

    @Inject
    lateinit var storageMonitor: StorageMonitor

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
    }

    override fun onTerminate() {
        storageMonitor.stopMonitoring()
        super.onTerminate()
    }
}
