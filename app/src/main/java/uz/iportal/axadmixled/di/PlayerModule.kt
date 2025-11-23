package uz.iportal.axadmixled.di

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.FileDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.RenderersFactory
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.AdaptiveTrackSelection
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.exoplayer.upstream.DefaultAllocator
import androidx.media3.exoplayer.util.EventLogger
import androidx.media3.exoplayer.video.MediaCodecVideoRenderer
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import timber.log.Timber
import uz.iportal.axadmixled.util.PlayerListener
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object PlayerModule {

    @OptIn(UnstableApi::class)
    @Provides
    @Singleton
    fun provideDefaultMediaSourceFactory(): DefaultMediaSourceFactory {
        // File-only data source for local media
        val fileDataSourceFactory = FileDataSource.Factory()
        return DefaultMediaSourceFactory(fileDataSourceFactory)
    }

    @UnstableApi
    @Provides
    @Singleton
    fun provideRenderersFactory(@ApplicationContext context: Context): RenderersFactory {
        return RenderersFactory { handler, videoListener, _, _, _ ->
            arrayOf(
                MediaCodecVideoRenderer(
                    context,
                    MediaCodecSelector.DEFAULT,
                    1500, // Fast joining for local files
                    false, // Disable fallback, no software decoding
                    handler,
                    videoListener,
                    10
                )
            )
        }
    }

    @OptIn(UnstableApi::class)
    @Provides
    @Singleton
    fun provideLoadControl(): DefaultLoadControl {
        val allocator = DefaultAllocator(
            true, // Use direct byte buffers
            32 * 1024 // 32KB segments (reduced from 64KB)
        )

        return DefaultLoadControl.Builder()
            .setAllocator(allocator)
            .setBufferDurationsMs(
                8000,  // min 8s
                15000, // max 15s
                3000,  // playback 3s
                1500   // rebuffer 1.5s
            )
            .setTargetBufferBytes(C.LENGTH_UNSET)
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(0, false) // No back buffer to save RAM
            .build()
    }

    @OptIn(UnstableApi::class)
    @Provides
    @Singleton
    fun provideTrackSelector(@ApplicationContext context: Context): DefaultTrackSelector {
        return DefaultTrackSelector(context, AdaptiveTrackSelection.Factory()).apply {
            parameters = buildUponParameters()
                .setExceedRendererCapabilitiesIfNecessary(false)
                // Disable all audio tracks
                .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, true)
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                // Disable adaptive selection completely
                .setAllowVideoMixedMimeTypeAdaptiveness(false)
                .setAllowVideoNonSeamlessAdaptiveness(false)
                // Constrain video resolution
                .setMaxVideoSizeSd()
                .setMaxVideoBitrate(512 * 1024) // Light bitrate reduce decoding load
                .build()
        }
    }

    @OptIn(UnstableApi::class)
    @Provides
    fun provideExoPlayer(
        @ApplicationContext context: Context,
        renderersFactory: RenderersFactory,
        playerListener: PlayerListener,
        defaultMediaSourceFactory: DefaultMediaSourceFactory,
        loadControl: DefaultLoadControl,
        trackSelector: DefaultTrackSelector
    ): ExoPlayer {
        return ExoPlayer.Builder(context)
            .setMediaSourceFactory(defaultMediaSourceFactory)
            .setRenderersFactory(renderersFactory)
            .setLoadControl(loadControl)
            .setTrackSelector(trackSelector)
            .setVideoScalingMode(C.VIDEO_SCALING_MODE_SCALE_TO_FIT)
            .setHandleAudioBecomingNoisy(false)
            .setPauseAtEndOfMediaItems(false)
            .build().apply {
                addListener(playerListener)
                addAnalyticsListener(object : EventLogger() {
                    override fun logd(msg: String) {
                        Timber.tag("EXOPLAYER").d(msg)
                    }

                    override fun loge(msg: String) {
                        Timber.tag("EXOPLAYER").e(msg)
                    }
                })
                repeatMode = Player.REPEAT_MODE_ALL
                playWhenReady = true
            }
    }
}