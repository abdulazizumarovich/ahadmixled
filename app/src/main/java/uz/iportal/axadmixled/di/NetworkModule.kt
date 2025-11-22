package uz.iportal.axadmixled.di

import android.content.Context
import com.chuckerteam.chucker.api.ChuckerInterceptor
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import timber.log.Timber
import uz.iportal.axadmixled.core.constants.ApiConstants
import uz.iportal.axadmixled.data.local.preferences.AuthPreferences
import uz.iportal.axadmixled.data.remote.api.AuthApi
import uz.iportal.axadmixled.data.remote.api.DeviceApi
import uz.iportal.axadmixled.data.remote.api.PlaylistApi
import uz.iportal.axadmixled.data.remote.api.ScreenshotApi
import uz.iportal.axadmixled.util.Constants
import java.util.concurrent.TimeUnit
import javax.inject.Provider
import javax.inject.Singleton
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder()
            .setLenient()
            .create()
    }

    @Provides
    @Singleton
    fun provideHttpLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor(
            logger = {
                Timber.tag("OKHTTP").d(it)
            }
        ).apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        @ApplicationContext context: Context,
        loggingInterceptor: HttpLoggingInterceptor
    ): OkHttpClient {
        return try {
            // Install a trust manager that does not validate certificate chains
            val trustAllCerts = arrayOf<TrustManager>(
                object : X509TrustManager {
                    override fun checkClientTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}
                    override fun checkServerTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}
                    override fun getAcceptedIssuers(): Array<java.security.cert.X509Certificate> = arrayOf()
                }
            )

            val sslContext = SSLContext.getInstance("SSL")
            sslContext.init(null, trustAllCerts, java.security.SecureRandom())

            val sslSocketFactory = sslContext.socketFactory

            OkHttpClient.Builder()
                .addInterceptor(loggingInterceptor)
                .addInterceptor(ChuckerInterceptor.Builder(context).build())
                .sslSocketFactory(sslSocketFactory, trustAllCerts[0] as X509TrustManager)
                .hostnameVerifier { _, _ -> true }
                .build()

        } catch (e: Exception) {
            throw RuntimeException(e)
        }
    }

    @Provides
//    @Singleton
    fun provideRetrofit(
        okHttpClient: OkHttpClient,
        authPreferences: AuthPreferences,
        gson: Gson
    ): Retrofit {
        return Retrofit.Builder()
            .baseUrl(ApiConstants.baseUrl(authPreferences.getIp()))
            .addConverterFactory(GsonConverterFactory.create(gson))
            .client(okHttpClient)
            .build()
    }

    @Provides
//    @Singleton
    fun provideAuthApi(retrofitProvider: Provider<Retrofit>): AuthApi {
        return retrofitProvider.get().create(AuthApi::class.java)
    }

    @Provides
//    @Singleton
    fun provideDeviceApi(retrofit: Retrofit): DeviceApi {
        return retrofit.create(DeviceApi::class.java)
    }

    @Provides
//    @Singleton
    fun providePlaylistApi(retrofit: Retrofit): PlaylistApi {
        return retrofit.create(PlaylistApi::class.java)
    }

    @Provides
//    @Singleton
    fun provideScreenshotApi(retrofit: Retrofit): ScreenshotApi {
        return retrofit.create(ScreenshotApi::class.java)
    }
}
