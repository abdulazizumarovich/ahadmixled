import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';

/// Manages pre-initialized video controllers for fast playlist switching
/// Keeps controllers for the first media of each ready playlist in memory
class PlaylistControllerManager {
  // Map of playlistId -> first video controller
  final Map<int, VideoPlayerController> _preInitializedControllers = {};

  // Map of playlistId -> preloaded image paths (for fast image display)
  final Map<int, String> _preloadedImages = {};

  // Track which playlists are currently being initialized
  final Set<int> _initializingPlaylists = {};

  // Cache for precached images by playlist
  final Map<int, List<ImageStreamCompleter>> _imageCacheByPlaylist = {};

  // Map of playlistId -> completer for tracking initialization completion
  final Map<int, Completer<bool>> _initializationCompleters = {};

  // Track fully initialized (ready) playlists
  final Set<int> _readyPlaylists = {};

  /// Pre-initialize controllers for all ready playlists
  /// Call this whenever playlist list changes
  ///
  /// Options:
  /// - sequential: Initialize playlists one by one (slower but more stable)
  /// - parallel: Initialize all at once (faster but may cause memory spikes)
  Future<void> preInitializePlaylists(
    List<PlaylistEntity> playlists,
    BuildContext? context, {
    bool sequential = false,
  }) async {
    AppLogger.info('🎬 [CONTROLLER_MANAGER] Pre-initializing ${playlists.length} playlists (${sequential ? 'SEQUENTIAL' : 'PARALLEL'})...');

    // Get IDs of playlists we should keep
    final currentPlaylistIds = playlists.map((p) => p.id).toSet();

    // Dispose controllers for playlists that are no longer in the list
    final idsToRemove = _preInitializedControllers.keys
        .where((id) => !currentPlaylistIds.contains(id))
        .toList();

    for (final id in idsToRemove) {
      AppLogger.info('🗑️ [CONTROLLER_MANAGER] Removing controller for removed playlist $id');
      await _disposeController(id);
    }

    // Filter playlists that need initialization
    final playlistsToInit = playlists.where((playlist) {
      // Skip if already initialized or currently initializing
      if (_preInitializedControllers.containsKey(playlist.id) ||
          _initializingPlaylists.contains(playlist.id)) {
        return false;
      }

      // Only pre-initialize if playlist is ready
      if (!playlist.status.isReady || !playlist.status.allDownloaded) {
        return false;
      }

      // Only pre-initialize if playlist has media
      if (playlist.mediaItems.isEmpty) {
        return false;
      }

      return true;
    }).toList();

    if (playlistsToInit.isEmpty) {
      AppLogger.info('✅ [CONTROLLER_MANAGER] All playlists already initialized');
      return;
    }

    AppLogger.info('🔄 [CONTROLLER_MANAGER] ${playlistsToInit.length} playlists need initialization');

    if (sequential) {
      // Initialize sequentially (one by one) for stability
      for (var i = 0; i < playlistsToInit.length; i++) {
        final playlist = playlistsToInit[i];
        AppLogger.info('⏳ [CONTROLLER_MANAGER] [${i + 1}/${playlistsToInit.length}] Initializing playlist ${playlist.id}...');

        // Check if context is still mounted before using it
        final contextToUse = (context != null && context.mounted) ? context : null;
        await _preInitializePlaylist(playlist, contextToUse);

        // Small delay between initializations to avoid overwhelming the system
        if (i < playlistsToInit.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      AppLogger.info('✅ [CONTROLLER_MANAGER] Sequential initialization complete!');
    } else {
      // Initialize in parallel (faster but uses more memory)
      for (final playlist in playlistsToInit) {
        // Check if context is still mounted before using it
        final contextToUse = (context != null && context.mounted) ? context : null;
        // Start pre-initialization in background (don't await)
        unawaited(_preInitializePlaylist(playlist, contextToUse));
      }
      AppLogger.info('🚀 [CONTROLLER_MANAGER] Parallel initialization started!');
    }
  }

  /// Pre-initialize a single playlist (first media only)
  Future<void> _preInitializePlaylist(
    PlaylistEntity playlist,
    BuildContext? context,
  ) async {
    _initializingPlaylists.add(playlist.id);

    // Create completer for this initialization
    final completer = Completer<bool>();
    _initializationCompleters[playlist.id] = completer;

    try {
      final firstMedia = playlist.mediaItems.first;

      // Check if media is downloaded
      if (!firstMedia.downloaded || firstMedia.localPath == null) {
        AppLogger.info('⏭️ [CONTROLLER_MANAGER] First media of playlist ${playlist.id} not downloaded, skipping');
        completer.complete(false);
        return;
      }

      final file = File(firstMedia.localPath!);
      if (!await file.exists()) {
        AppLogger.info('❌ [CONTROLLER_MANAGER] File not found for playlist ${playlist.id}');
        completer.complete(false);
        return;
      }

      // Validate file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.info('❌ [CONTROLLER_MANAGER] Empty file for playlist ${playlist.id}');
        completer.complete(false);
        return;
      }

      if (firstMedia.mediaType == 'video') {
        // Pre-initialize video controller
        AppLogger.info('🎬 [CONTROLLER_MANAGER] Pre-initializing VIDEO for playlist ${playlist.id}: ${firstMedia.mediaName}');

        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        await controller.setLooping(false);

        _preInitializedControllers[playlist.id] = controller;
        _readyPlaylists.add(playlist.id);
        AppLogger.info('✅ [CONTROLLER_MANAGER] Video pre-initialized for playlist ${playlist.id}');
        completer.complete(true);

      } else if (firstMedia.mediaType == 'image') {
        // Pre-cache image
        AppLogger.info('🖼️ [CONTROLLER_MANAGER] Pre-caching IMAGE for playlist ${playlist.id}: ${firstMedia.mediaName}');

        _preloadedImages[playlist.id] = firstMedia.localPath!;

        // Precache image if context is available and still mounted
        if (context != null) {
          if (!context.mounted) {
            AppLogger.info('⚠️ [CONTROLLER_MANAGER] Context no longer mounted, marking as ready anyway');
            _readyPlaylists.add(playlist.id);
            completer.complete(true);
            return;
          }

          try {
            await precacheImage(FileImage(file), context);
            _readyPlaylists.add(playlist.id);
            AppLogger.info('✅ [CONTROLLER_MANAGER] Image pre-cached for playlist ${playlist.id}');
            completer.complete(true);
          } catch (e) {
            AppLogger.error('⚠️ [CONTROLLER_MANAGER] Failed to precache image for playlist ${playlist.id}', e);
            // Still mark as ready - we can load it on demand
            _readyPlaylists.add(playlist.id);
            completer.complete(true);
          }
        } else {
          // No context, but image path is stored
          _readyPlaylists.add(playlist.id);
          completer.complete(true);
        }
      } else {
        completer.complete(false);
      }
    } catch (e) {
      AppLogger.error('❌ [CONTROLLER_MANAGER] Failed to pre-initialize playlist ${playlist.id}', e);
      completer.complete(false);
    } finally {
      _initializingPlaylists.remove(playlist.id);
    }
  }

  /// Get pre-initialized controller for a playlist (if available)
  /// Returns null if not pre-initialized
  VideoPlayerController? getController(int playlistId) {
    return _preInitializedControllers[playlistId];
  }

  /// Get pre-loaded image path for a playlist (if available)
  String? getPreloadedImagePath(int playlistId) {
    return _preloadedImages[playlistId];
  }

  /// Remove controller from pool (called when switching to this playlist)
  /// This ensures the controller is not disposed by the manager
  VideoPlayerController? takeController(int playlistId) {
    AppLogger.info('📤 [CONTROLLER_MANAGER] Taking controller for playlist $playlistId');
    return _preInitializedControllers.remove(playlistId);
  }

  /// Return a controller back to the pool for re-initialization
  /// Call this when switching away from a playlist
  Future<void> returnController(
    int playlistId,
    PlaylistEntity playlist,
    BuildContext? context,
  ) async {
    AppLogger.info('📥 [CONTROLLER_MANAGER] Returning controller for playlist $playlistId for re-initialization');

    // Dispose old controller if exists
    await _disposeController(playlistId);

    // Check if context is still mounted before re-initializing
    if (context != null && !context.mounted) {
      AppLogger.info('⚠️ [CONTROLLER_MANAGER] Context no longer mounted, skipping re-initialization');
      return;
    }

    // Re-initialize in background
    unawaited(_preInitializePlaylist(playlist, context));
  }

  /// Dispose controller for a specific playlist
  Future<void> _disposeController(int playlistId) async {
    final controller = _preInitializedControllers.remove(playlistId);
    if (controller != null) {
      try {
        await controller.dispose();
        AppLogger.info('🗑️ [CONTROLLER_MANAGER] Disposed controller for playlist $playlistId');
      } catch (e) {
        AppLogger.error('⚠️ [CONTROLLER_MANAGER] Error disposing controller for playlist $playlistId', e);
      }
    }

    // Remove preloaded image
    _preloadedImages.remove(playlistId);

    // Clear image cache for this playlist
    final _ = _imageCacheByPlaylist.remove(playlistId);

    // Remove from ready playlists and completers
    _readyPlaylists.remove(playlistId);
    _initializationCompleters.remove(playlistId);
  }

  /// Clear image cache for a specific playlist
  /// Call this when playlist is reloaded to avoid stale images
  void clearImageCache(int playlistId) {
    AppLogger.info('🗑️ [CONTROLLER_MANAGER] Clearing image cache for playlist $playlistId');

    // Remove from preloaded images
    _preloadedImages.remove(playlistId);

    // Clear cached images (automatically garbage collected)
    _imageCacheByPlaylist.remove(playlistId);
  }

  /// Dispose all controllers and clear all caches
  Future<void> disposeAll() async {
    AppLogger.info('🗑️ [CONTROLLER_MANAGER] Disposing all controllers...');

    final controllers = _preInitializedControllers.values.toList();
    _preInitializedControllers.clear();

    for (final controller in controllers) {
      try {
        await controller.dispose();
      } catch (e) {
        AppLogger.error('⚠️ [CONTROLLER_MANAGER] Error disposing controller', e);
      }
    }

    _preloadedImages.clear();
    _imageCacheByPlaylist.clear();
    _initializingPlaylists.clear();
    _readyPlaylists.clear();
    _initializationCompleters.clear();

    AppLogger.info('✅ [CONTROLLER_MANAGER] All controllers disposed');
  }

  /// Check if a playlist has a pre-initialized controller
  bool hasController(int playlistId) {
    return _preInitializedControllers.containsKey(playlistId);
  }

  /// Check if a playlist is currently being initialized
  bool isInitializing(int playlistId) {
    return _initializingPlaylists.contains(playlistId);
  }

  /// Check if a playlist is fully ready for instant playback
  bool isPlaylistReady(int playlistId) {
    return _readyPlaylists.contains(playlistId);
  }

  /// Wait for a playlist to be fully initialized (with timeout)
  /// Returns true if ready, false if timeout or failed
  Future<bool> waitForPlaylistReady(int playlistId, {Duration timeout = const Duration(seconds: 10)}) async {
    // If already ready, return immediately
    if (_readyPlaylists.contains(playlistId)) {
      AppLogger.info('⚡ [CONTROLLER_MANAGER] Playlist $playlistId already ready');
      return true;
    }

    // If not initializing and not ready, it means initialization hasn't started
    if (!_initializingPlaylists.contains(playlistId) && !_initializationCompleters.containsKey(playlistId)) {
      AppLogger.info('⚠️ [CONTROLLER_MANAGER] Playlist $playlistId not initialized yet');
      return false;
    }

    // Wait for completer with timeout
    final completer = _initializationCompleters[playlistId];
    if (completer == null) {
      AppLogger.info('⚠️ [CONTROLLER_MANAGER] No completer for playlist $playlistId');
      return false;
    }

    try {
      AppLogger.info('⏳ [CONTROLLER_MANAGER] Waiting for playlist $playlistId to be ready...');
      final result = await completer.future.timeout(timeout);
      AppLogger.info('${result ? '✅' : '❌'} [CONTROLLER_MANAGER] Playlist $playlistId ready: $result');
      return result;
    } catch (e) {
      AppLogger.error('⏱️ [CONTROLLER_MANAGER] Timeout waiting for playlist $playlistId', e);
      return false;
    }
  }

  /// Wait for ALL playlists to be ready
  Future<void> waitForAllPlaylistsReady(List<int> playlistIds, {Duration timeout = const Duration(seconds: 30)}) async {
    AppLogger.info('⏳ [CONTROLLER_MANAGER] Waiting for ${playlistIds.length} playlists to be ready...');

    final futures = playlistIds.map((id) => waitForPlaylistReady(id, timeout: timeout)).toList();

    try {
      final results = await Future.wait(futures);
      final readyCount = results.where((r) => r).length;
      AppLogger.info('✅ [CONTROLLER_MANAGER] $readyCount/${playlistIds.length} playlists ready');
    } catch (e) {
      AppLogger.error('❌ [CONTROLLER_MANAGER] Error waiting for playlists', e);
    }
  }

  /// Get statistics about pre-initialized controllers
  Map<String, dynamic> getStats() {
    return {
      'total_controllers': _preInitializedControllers.length,
      'total_images': _preloadedImages.length,
      'initializing': _initializingPlaylists.length,
      'ready': _readyPlaylists.length,
      'playlist_ids': _preInitializedControllers.keys.toList(),
      'ready_playlist_ids': _readyPlaylists.toList(),
    };
  }
}