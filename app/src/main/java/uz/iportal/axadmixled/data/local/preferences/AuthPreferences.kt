package uz.iportal.axadmixled.data.local.preferences

import android.content.Context
import androidx.core.content.edit
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import uz.iportal.axadmixled.core.constants.ApiConstants
import uz.iportal.axadmixled.domain.model.AuthTokens
import uz.iportal.axadmixled.util.Constants
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthPreferences @Inject constructor(
    @ApplicationContext context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        Constants.PREFS_NAME,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveTokens(tokens: AuthTokens) {
        sharedPreferences.edit().apply {
            putString(Constants.KEY_ACCESS_TOKEN, tokens.access)
            putString(Constants.KEY_REFRESH_TOKEN, tokens.refresh)
            putLong(Constants.KEY_TOKEN_EXPIRES_AT, tokens.expiresAt)
            apply()
        }
    }

    fun getAccessToken(): String? {
        return sharedPreferences.getString(Constants.KEY_ACCESS_TOKEN, null)
    }

    fun getRefreshToken(): String? {
        return sharedPreferences.getString(Constants.KEY_REFRESH_TOKEN, null)
    }

    fun getTokenExpiresAt(): Long {
        return sharedPreferences.getLong(Constants.KEY_TOKEN_EXPIRES_AT, 0)
    }

    fun isTokenExpired(): Boolean {
        val expiresAt = getTokenExpiresAt()
        return System.currentTimeMillis() >= expiresAt
    }

    fun clearTokens() {
        sharedPreferences.edit().apply {
            remove(Constants.KEY_ACCESS_TOKEN)
            remove(Constants.KEY_REFRESH_TOKEN)
            remove(Constants.KEY_TOKEN_EXPIRES_AT)
            apply()
        }
    }

    fun saveDeviceSnNumber(snNumber: String) {
        sharedPreferences.edit().apply {
            putString(Constants.KEY_DEVICE_SN, snNumber)
            apply()
        }
    }

    fun getDeviceSnNumber(): String? {
        return sharedPreferences.getString(Constants.KEY_DEVICE_SN, null)
    }

    fun saveIp(ip: String?) {
        sharedPreferences.edit {
            putString(Constants.KEY_IP, ip)
        }
    }

    fun getIp(): String {
        return sharedPreferences.getString(Constants.KEY_IP, null) ?: ApiConstants.DOMAIN_NAME
    }
}
