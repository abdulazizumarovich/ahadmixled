package uz.iportal.axadmixled.di

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.RenderersFactory
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.video.MediaCodecVideoRenderer
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object PlayerModule {

    @OptIn(UnstableApi::class)
    @Provides
    @Singleton
    fun provideDefaultMediaSourceFactory(
        @ApplicationContext context: Context,
        okHttpClient: OkHttpClient
    ): DefaultMediaSourceFactory {
        val httpFactory = OkHttpDataSource.Factory(okHttpClient)
        val dataSourceFactory = DefaultDataSource.Factory(
            context,
            httpFactory
        )
        return DefaultMediaSourceFactory(dataSourceFactory)
    }

    @UnstableApi
    @Provides
    @Singleton
    fun provideRenderersFactory(@ApplicationContext context: Context): RenderersFactory {
        return RenderersFactory { handler, videoListener, _, _, _ ->
            arrayOf(
                // video only renderer
                MediaCodecVideoRenderer(
                    context,
                    MediaCodecSelector.DEFAULT,
                    0,
                    false,
                    handler,
                    videoListener,
                    50
                )
            )
        }
    }
}