package uz.iportal.axadmixled.data.repository

import android.content.Context
import com.google.android.gms.time.TrustedTime
import com.google.android.gms.time.TrustedTimeClient
import timber.log.Timber
import uz.iportal.axadmixled.domain.repository.TimeRepository
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TimeRepositoryImpl @Inject constructor() : TimeRepository {

    private var trustedTimeClient: TrustedTimeClient? = null

    override fun initialize(context: Context) {
        TrustedTime.createClient(context)
            .addOnSuccessListener {
                Timber.tag("TimeRepository").d("TrustedTimeClient initialized")
                trustedTimeClient = it
            }
            .addOnFailureListener { e ->
                Timber.tag("TimeRepository").e(e, "Failed to initialize TrustedTimeClient")
            }
    }

    override fun getCurrentTimeMillis(): Long {
        return trustedTimeClient?.computeCurrentUnixEpochMillis()
            ?: System.currentTimeMillis()
    }
}