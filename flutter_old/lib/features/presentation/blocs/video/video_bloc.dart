import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/datasources/local/device_local_datasource.dart';
import 'package:tv_monitor/features/domain/entities/device_screens_entity.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';
import 'package:tv_monitor/features/domain/usecases/video/capture_screenshot_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/video/get_device_screens_usecase.dart';
import 'package:tv_monitor/core/utils/download_debug_logger.dart';
import 'package:tv_monitor/features/domain/usecases/video/download_playlist_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/video/get_local_playlists_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/video/send_playlist_status_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/video/delete_playlist_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/video/redownload_media_item_usecase.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final GetDeviceScreensUseCase getDeviceScreensUseCase;
  final DownloadPlaylistUseCase downloadPlaylistUseCase;
  final GetLocalPlaylistsUseCase getLocalPlaylistsUseCase;
  final SendPlaylistStatusUseCase sendPlaylistStatusUseCase;
  final DeletePlaylistUseCase deletePlaylistUseCase;
  final CaptureScreenshotUseCase captureScreenshotUseCase;
  final RedownloadMediaItemUseCase redownloadMediaItemUseCase;
  final DeviceLocalDataSource deviceLocalDataSource;

  VideoBloc({
    required this.getDeviceScreensUseCase,
    required this.downloadPlaylistUseCase,
    required this.getLocalPlaylistsUseCase,
    required this.sendPlaylistStatusUseCase,
    required this.deletePlaylistUseCase,
    required this.captureScreenshotUseCase,
    required this.redownloadMediaItemUseCase,
    required this.deviceLocalDataSource,
  }) : super(const VideoInitial()) {
    on<LoadDeviceScreens>(_onLoadDeviceScreens);
    on<DownloadPlaylist>(_onDownloadPlaylist);
    on<LoadLocalPlaylists>(_onLoadLocalPlaylists);
    on<SelectPlaylist>(_onSelectPlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<PlayVideo>(_onPlayVideo);
    on<PauseVideo>(_onPauseVideo);
    on<PlayNextVideo>(_onPlayNextVideo);
    on<PlayPreviousVideo>(_onPlayPreviousVideo);
    on<CaptureAndUploadScreenshot>(_onCaptureAndUploadScreenshot);
    on<ShowTextOverlay>(_onShowTextOverlay);
    on<HideTextOverlay>(_onHideTextOverlay);
    on<SetBrightness>(_onSetBrightness);
    on<SetVolume>(_onSetVolume);
    on<RedownloadMediaItem>(_onRedownloadMediaItem);
  }

  Future<void> _onLoadDeviceScreens(LoadDeviceScreens event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('📡 Loading device screens for device: ${event.deviceId}');

    // Preserve current playback state during reload
    final currentState = state is VideoLoaded ? state as VideoLoaded : null;
    final wasPlaying = currentState?.isPlaying ?? false;
    final currentMediaIndex = currentState?.currentMediaIndex ?? 0;
    final previousPlaylistId = currentState?.currentPlaylist?.id;
    final textOverlayConfig = currentState?.textOverlayConfig;
    final brightness = currentState?.brightness ?? 50;
    final volume = currentState?.volume ?? 50;

    AppLogger.videoInfo('🔄 Preserving state - wasPlaying: $wasPlaying, playlistId: $previousPlaylistId, mediaIndex: $currentMediaIndex');

    final result = await getDeviceScreensUseCase(event.deviceId);

    result.fold(
      (failure) {
        AppLogger.videoError('❌ Failed to load device screens: ${failure.message}');
        AppLogger.videoInfo('🔄 Attempting to load local playlists as fallback...');
        // Try to load local playlists as fallback
        add(const LoadLocalPlaylists());
      },
      (deviceScreens) {
        final playlists = deviceScreens.frontScreen?.playlists ?? [];
        final serverPlaylistId = deviceScreens.frontScreen?.currentPlaylist;

        AppLogger.videoInfo('📋 Received ${playlists.length} playlists from server');

        // STRICT VALIDATION: Only show playlists that are fully ready
        final readyPlaylists = _filterReadyPlaylists(playlists);

        if (readyPlaylists.isEmpty && playlists.isNotEmpty) {
          AppLogger.videoInfo('⏳ No playlists are ready yet - preserving current playback state');

          // If we have a previous playlist that was playing, try to restore it
          if (currentState != null && previousPlaylistId != null) {
            final previousPlaylist = playlists.where((p) => p.id == previousPlaylistId).firstOrNull;

            if (previousPlaylist != null) {
              // Restore the previous playlist to maintain playback
              AppLogger.videoInfo('✅ Restoring previous playlist: ${previousPlaylist.name}');
              emit(VideoLoaded(
                deviceScreens: deviceScreens,
                playlists: playlists,
                currentPlaylist: previousPlaylist,
                currentMediaIndex: currentMediaIndex,
                isPlaying: wasPlaying,
                textOverlayConfig: textOverlayConfig,
                brightness: brightness,
                volume: volume,
                isWebSocketReload: true, // CRITICAL: This is from WebSocket
              ));
              return;
            }
          }

          // Otherwise emit with no current playlist
          emit(VideoLoaded(
            deviceScreens: deviceScreens,
            playlists: playlists,
            currentPlaylist: null,
            isWebSocketReload: true, // CRITICAL: This is from WebSocket
          ));
          return;
        }

        // Find current playlist - prioritize previously playing playlist
        PlaylistEntity? currentPlaylist;
        int mediaIndex = currentMediaIndex;

        // First, try to restore the previously playing playlist if it exists and is ready
        if (previousPlaylistId != null) {
          try {
            currentPlaylist = readyPlaylists.firstWhere((p) => p.id == previousPlaylistId);
            AppLogger.videoInfo('✅ Restored previously playing playlist: ${currentPlaylist.name}');

            // Validate media index is still valid
            if (mediaIndex >= currentPlaylist.mediaItems.length) {
              mediaIndex = 0;
            }
          } catch (e) {
            AppLogger.videoInfo('⚠️ Previous playlist not ready, trying server recommendation');
            currentPlaylist = null;
          }
        }

        // If we couldn't restore previous playlist, try server's recommended playlist
        if (currentPlaylist == null && serverPlaylistId != null) {
          try {
            currentPlaylist = readyPlaylists.firstWhere((p) => p.id == serverPlaylistId);
            AppLogger.videoInfo('✅ Selected ready playlist from server: ${currentPlaylist.name}');
            mediaIndex = 0; // Reset to first media when switching playlists
          } catch (e) {
            AppLogger.videoInfo('⚠️ Server recommended playlist not ready');
          }
        }

        // Finally, fall back to first ready playlist
        if (currentPlaylist == null) {
          currentPlaylist = readyPlaylists.isNotEmpty ? readyPlaylists.first : null;
          if (currentPlaylist != null) {
            AppLogger.videoInfo('✅ Using first available ready playlist: ${currentPlaylist.name}');
            mediaIndex = 0; // Reset to first media when switching playlists
          }
        }

        if (currentPlaylist == null && playlists.isEmpty) {
          AppLogger.videoInfo('🔄 No playlists from server, trying local playlists...');
          add(const LoadLocalPlaylists());
          return;
        }

        // Emit state with validated ready playlists and preserved playback state
        if (currentPlaylist != null) {
          AppLogger.videoInfo('✅ Emitting VideoLoaded with playlist: ${currentPlaylist.name} (preserving playback state)');
          emit(VideoLoaded(
            deviceScreens: deviceScreens,
            playlists: playlists,
            currentPlaylist: currentPlaylist,
            currentMediaIndex: mediaIndex,
            isPlaying: wasPlaying,
            textOverlayConfig: textOverlayConfig,
            brightness: brightness,
            volume: volume,
            isWebSocketReload: true, // CRITICAL: This is from WebSocket - trigger download check
          ));

          // CRITICAL DEBUG: Log state emit
          DownloadDebugLogger.logStateEmit(
            eventName: 'LoadDeviceScreens',
            isWebSocketReload: true,
            playlistName: currentPlaylist.name,
            playlistId: currentPlaylist.id,
          );
        } else {
          AppLogger.videoInfo('⏳ No ready playlists available yet');
          emit(VideoLoaded(
            deviceScreens: deviceScreens,
            playlists: playlists,
            currentPlaylist: null,
            isWebSocketReload: true, // CRITICAL: This is from WebSocket - trigger download check
          ));
        }
      },
    );
  }

  /// Filter playlists to only include those that are fully downloaded and ready
  List<PlaylistEntity> _filterReadyPlaylists(List<PlaylistEntity> playlists) {
    return playlists.where((playlist) {
      // Check status flags
      if (!playlist.status.isReady || !playlist.status.allDownloaded) {
        AppLogger.videoInfo('⏸️ Playlist "${playlist.name}" not ready (isReady: ${playlist.status.isReady}, allDownloaded: ${playlist.status.allDownloaded})');
        return false;
      }

      // Verify all media items are downloaded
      final allMediaDownloaded = playlist.mediaItems.every((item) => item.downloaded == true && item.localPath != null);
      if (!allMediaDownloaded) {
        AppLogger.videoInfo('⏸️ Playlist "${playlist.name}" has undownloaded media items');
        return false;
      }

      AppLogger.videoInfo('✅ Playlist "${playlist.name}" is ready for playback');
      return true;
    }).toList();
  }

  Future<void> _onDownloadPlaylist(DownloadPlaylist event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('📥 Starting download for playlist: ${event.playlist.name}');

    emit(
      PlaylistDownloading(playlist: event.playlist, downloadedItems: 0, totalItems: event.playlist.mediaItems.length),
    );

    final result = await downloadPlaylistUseCase(
      DownloadPlaylistParams(
        playlist: event.playlist,
        onProgress: (downloadedItems, totalItems) {
          emit(PlaylistDownloading(playlist: event.playlist, downloadedItems: downloadedItems, totalItems: totalItems));
        },
      ),
    );

    result.fold(
      (failure) {
        AppLogger.videoError('❌ Download failed: ${failure.message}');
        emit(VideoError(message: failure.message));
      },
      (downloadedPlaylist) {
        AppLogger.videoInfo('✅ Download completed: ${downloadedPlaylist.name}');
        // Reload all playlists after download
        add(const LoadLocalPlaylists());
      },
    );
  }

  Future<void> _onLoadLocalPlaylists(LoadLocalPlaylists event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('💾 Loading local playlists from database...');

    // Preserve current state if available
    final currentState = state is VideoLoaded ? state as VideoLoaded : null;
    final wasPlaying = currentState?.isPlaying ?? false;
    final currentMediaIndex = currentState?.currentMediaIndex ?? 0;
    final currentPlaylistId = currentState?.currentPlaylist?.id;

    // Only show loading state if we don't have a current state (initial load)
    if (currentState == null) {
      emit(const VideoLoading());
    }

    final result = await getLocalPlaylistsUseCase();

    result.fold(
      (failure) {
        AppLogger.videoError('❌ Failed to load local playlists: ${failure.message}');
        emit(VideoError(message: failure.message));
      },
      (playlists) {
        AppLogger.videoInfo('📋 Found ${playlists.length} local playlists from database');

        // Log all playlists for debugging
        for (var i = 0; i < playlists.length; i++) {
          final p = playlists[i];
          AppLogger.videoInfo('   Playlist $i: "${p.name}" (ID: ${p.id})');
          AppLogger.videoInfo('      - Status: isReady=${p.status.isReady}, allDownloaded=${p.status.allDownloaded}');
          AppLogger.videoInfo('      - Media items: ${p.mediaItems.length}');
          final downloadedCount = p.mediaItems.where((m) => m.downloaded == true).length;
          AppLogger.videoInfo('      - Downloaded: $downloadedCount/${p.mediaItems.length}');
        }

        // IMPORTANT: Filter to only include READY playlists
        final readyPlaylists = _filterReadyPlaylists(playlists);
        AppLogger.videoInfo('✅ ${readyPlaylists.length}/${playlists.length} playlists are ready for playback');

        // Try to restore the previous playlist (from READY playlists only)
        PlaylistEntity? currentPlaylist;
        int mediaIndex = currentMediaIndex;

        if (currentPlaylistId != null) {
          try {
            // Try to find in ready playlists first
            currentPlaylist = readyPlaylists.firstWhere((p) => p.id == currentPlaylistId);
            AppLogger.videoInfo('✅ Restored previous ready playlist: ${currentPlaylist.name}');

            // Validate media index is still valid
            if (mediaIndex >= currentPlaylist.mediaItems.length) {
              mediaIndex = 0;
            }
          } catch (e) {
            AppLogger.videoInfo('⚠️ Previous playlist not ready, selecting first ready playlist');
            currentPlaylist = readyPlaylists.isNotEmpty ? readyPlaylists.first : null;
            mediaIndex = 0;
          }
        } else {
          // Select first ready playlist
          currentPlaylist = readyPlaylists.isNotEmpty ? readyPlaylists.first : null;
          mediaIndex = 0;
        }

        if (currentPlaylist != null) {
          AppLogger.videoInfo('✅ Selected ready playlist: ${currentPlaylist.name}');
        } else {
          if (playlists.isEmpty) {
            AppLogger.videoError('❌ No playlists found in database');
          } else if (readyPlaylists.isEmpty) {
            AppLogger.videoError('⚠️ Found ${playlists.length} playlists but none are ready for playback');
          }
        }

        AppLogger.videoInfo('✅ VideoLoaded state emitted with ${readyPlaylists.length} ready playlists');
        emit(VideoLoaded(
          playlists: playlists,
          currentPlaylist: currentPlaylist,
          currentMediaIndex: mediaIndex,
          isPlaying: wasPlaying,
          deviceScreens: null, // CRITICAL: Local load - no deviceScreens
          textOverlayConfig: currentState?.textOverlayConfig,
          brightness: currentState?.brightness ?? 50,
          volume: currentState?.volume ?? 50,
          isWebSocketReload: false, // CRITICAL: Local load - NOT a WebSocket reload
        ));
      },
    );
  }

  Future<void> _onSelectPlaylist(SelectPlaylist event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('🔀 SelectPlaylist event received - playlistId: ${event.playlistId}');
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      AppLogger.videoInfo('📋 Available playlists: ${currentState.playlists.map((p) => p.id).toList()}');
      AppLogger.videoInfo('📋 Current playlist ID: ${currentState.currentPlaylist?.id}');

      try {
        final selectedPlaylist = currentState.playlists.firstWhere((p) => p.id == event.playlistId);
        AppLogger.videoInfo('✅ Found playlist: ${selectedPlaylist.name} (ID: ${selectedPlaylist.id})');

        // CRITICAL FIX: Check if this is the same playlist as currently playing
        final isSamePlaylist = currentState.currentPlaylist?.id == event.playlistId;

        if (isSamePlaylist) {
          // Same playlist - RESTART from beginning and start playing immediately
          AppLogger.videoInfo('🔄 Same playlist ID detected - restarting from beginning');
          emit(currentState.copyWith(
            currentPlaylist: selectedPlaylist,
            currentMediaIndex: 0,
            isPlaying: true, // Start playing immediately
          ));

          // CRITICAL DEBUG: Log state emit
          DownloadDebugLogger.logStateEmit(
            eventName: 'SelectPlaylist (Same)',
            isWebSocketReload: false,
            playlistName: selectedPlaylist.name,
            playlistId: selectedPlaylist.id,
          );

          AppLogger.videoInfo('✅ Playlist restarted from beginning');
        } else {
          // Different playlist - switch and start playing immediately
          AppLogger.videoInfo('🔀 Switching to different playlist - starting playback');
          emit(currentState.copyWith(
            currentPlaylist: selectedPlaylist,
            currentMediaIndex: 0,
            isPlaying: true, // Start playing immediately
          ));

          // CRITICAL DEBUG: Log state emit
          DownloadDebugLogger.logStateEmit(
            eventName: 'SelectPlaylist',
            isWebSocketReload: false,
            playlistName: selectedPlaylist.name,
            playlistId: selectedPlaylist.id,
          );

          AppLogger.videoInfo('✅ Switched to playlist successfully');
        }
      } catch (e) {
        AppLogger.videoError('❌ Playlist with ID ${event.playlistId} not found, using first playlist');
        if (currentState.playlists.isNotEmpty) {
          emit(
            currentState.copyWith(
              currentPlaylist: currentState.playlists.first,
              currentMediaIndex: 0,
              isPlaying: true, // Start playing immediately even on fallback
            ),
          );
        }
      }
    } else {
      AppLogger.videoError('❌ SelectPlaylist event received but state is not VideoLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onDeletePlaylist(DeletePlaylistEvent event, Emitter<VideoState> emit) async {
    final result = await deletePlaylistUseCase(event.playlistId);

    result.fold((failure) => emit(VideoError(message: failure.message)), (_) {
      add(const LoadLocalPlaylists());
    });
  }

  Future<void> _onPlayVideo(PlayVideo event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('🎬 PlayVideo event received - index: ${event.index}');
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      final newState = currentState.copyWith(
        currentMediaIndex: event.index,
        isPlaying: true,
      );
      AppLogger.videoInfo('📤 Emitting new state: currentMediaIndex=${event.index}, isPlaying=true');
      emit(newState);
      AppLogger.videoInfo('✅ State emitted successfully');
    } else {
      AppLogger.videoError('❌ PlayVideo event received but state is not VideoLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onPauseVideo(PauseVideo event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('⏸️ PauseVideo event received');
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      final newState = currentState.copyWith(
        isPlaying: false,
      );
      AppLogger.videoInfo('📤 Emitting new state: isPlaying=false');
      emit(newState);
      AppLogger.videoInfo('✅ State emitted successfully');
    } else {
      AppLogger.videoError('❌ PauseVideo event received but state is not VideoLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onPlayNextVideo(PlayNextVideo event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('⏭️ PlayNextVideo event received');
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      final mediaItemsCount = currentState.currentPlaylist?.mediaItems.length ?? 0;
      if (mediaItemsCount > 0) {
        final nextIndex = (currentState.currentMediaIndex + 1) % mediaItemsCount;
        AppLogger.videoInfo('✅ Moving to next media: $nextIndex');

        final newState = currentState.copyWith(
          currentMediaIndex: nextIndex,
          isPlaying: true,
        );
        AppLogger.videoInfo('📤 Emitting new state: currentMediaIndex=$nextIndex, isPlaying=true');
        emit(newState);
        AppLogger.videoInfo('✅ State emitted successfully');
      } else {
        AppLogger.videoError('❌ No media items in current playlist');
      }
    } else {
      AppLogger.videoError('❌ PlayNextVideo event received but state is not VideoLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onPlayPreviousVideo(PlayPreviousVideo event, Emitter<VideoState> emit) async {
    AppLogger.videoInfo('⏮️ PlayPreviousVideo event received');
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      final mediaItemsCount = currentState.currentPlaylist?.mediaItems.length ?? 0;
      if (mediaItemsCount > 0) {
        final previousIndex = currentState.currentMediaIndex > 0
            ? currentState.currentMediaIndex - 1
            : mediaItemsCount - 1;
        AppLogger.videoInfo('✅ Moving to previous media: $previousIndex');
        emit(currentState.copyWith(
          currentMediaIndex: previousIndex,
          isPlaying: true,
        ));
      } else {
        AppLogger.videoError('❌ No media items in current playlist');
      }
    } else {
      AppLogger.videoError('❌ PlayPreviousVideo event received but state is not VideoLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onCaptureAndUploadScreenshot(CaptureAndUploadScreenshot event, Emitter<VideoState> emit) async {
    final result = await captureScreenshotUseCase(
      CaptureScreenshotParams(deviceId: event.deviceId, mediaId: event.mediaId, imageBytes: event.imageBytes),
    );

    result.fold(
      (failure) {
        AppLogger.videoError('Screenshot upload failed: ${failure.message}');
      },
      (_) {
        AppLogger.videoInfo('Screenshot uploaded successfully');
      },
    );
  }

  Future<void> _onShowTextOverlay(ShowTextOverlay event, Emitter<VideoState> emit) async {
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      emit(currentState.copyWith(
        textOverlayConfig: event.config,
      ));
    }
  }

  Future<void> _onHideTextOverlay(HideTextOverlay event, Emitter<VideoState> emit) async {
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      emit(currentState.copyWith(
        clearTextOverlay: true,
      ));
    }
  }

  Future<void> _onSetBrightness(SetBrightness event, Emitter<VideoState> emit) async {
    try {
      AppLogger.videoInfo('Setting brightness to: ${event.brightness}');
      await deviceLocalDataSource.saveBrightness(event.brightness);
      if (state is VideoLoaded) {
        final currentState = state as VideoLoaded;
        emit(currentState.copyWith(
          brightness: event.brightness,
        ));
      }
      AppLogger.videoInfo('Brightness set successfully');
    } catch (e) {
      AppLogger.videoError('Failed to set brightness', e);
    }
  }

  Future<void> _onSetVolume(SetVolume event, Emitter<VideoState> emit) async {
    try {
      AppLogger.videoInfo('Setting volume to: ${event.volume}');
      await deviceLocalDataSource.saveVolume(event.volume);
      if (state is VideoLoaded) {
        final currentState = state as VideoLoaded;
        emit(currentState.copyWith(
          volume: event.volume,
        ));
      }
      AppLogger.videoInfo('Volume set successfully');
    } catch (e) {
      AppLogger.videoError('Failed to set volume', e);
    }
  }

  Future<void> _onRedownloadMediaItem(RedownloadMediaItem event, Emitter<VideoState> emit) async {
    if (state is! VideoLoaded) return;

    final currentState = state as VideoLoaded;
    if (currentState.currentPlaylist == null) return;

    emit(MediaItemRedownloading(mediaIndex: event.mediaIndex, progress: 0.0));

    final result = await redownloadMediaItemUseCase(
      RedownloadMediaItemParams(
        playlist: currentState.currentPlaylist!,
        mediaIndex: event.mediaIndex,
        onProgress: (progress) {
          emit(MediaItemRedownloading(mediaIndex: event.mediaIndex, progress: progress));
        },
      ),
    );

    result.fold(
      (failure) {
        AppLogger.videoError('Failed to re-download media item: ${failure.message}');
        emit(VideoError(message: 'Failed to re-download media: ${failure.message}'));
        // Return to previous state after error
        Future.delayed(const Duration(seconds: 2), () {
          add(const LoadLocalPlaylists());
        });
      },
      (updatedPlaylist) {
        AppLogger.videoInfo('Media item re-downloaded successfully');
        // Update the playlist in the state
        final updatedPlaylists = currentState.playlists.map((p) {
          if (p.id == updatedPlaylist.id) {
            return updatedPlaylist;
          }
          return p;
        }).toList();

        emit(currentState.copyWith(
          playlists: updatedPlaylists,
          currentPlaylist: updatedPlaylist,
        ));

        // Trigger replay of the video
        add(PlayVideo(index: event.mediaIndex));
      },
    );
  }
}
