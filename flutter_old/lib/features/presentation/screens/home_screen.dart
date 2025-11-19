import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tv_monitor/injection_container.dart';
import 'package:tv_monitor/features/presentation/blocs/video/video_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/websocket/websocket_bloc.dart';
import 'package:tv_monitor/features/presentation/widgets/video_player_widget.dart';
import 'package:tv_monitor/features/data/datasources/local/auth_local_datasource.dart';
import 'package:tv_monitor/features/data/datasources/local/device_local_datasource.dart';
import 'package:tv_monitor/core/utils/download_debug_logger.dart';
import 'package:tv_monitor/features/presentation/screens/loading_screen.dart';
import 'package:tv_monitor/features/data/services/websocket_reconnection_service.dart';
import 'package:tv_monitor/features/data/services/device_memory_monitor.dart';
import 'package:tv_monitor/features/data/services/app_state_manager.dart';
import 'package:tv_monitor/features/data/services/background_download_service.dart';
import 'package:tv_monitor/features/domain/repositories/websocket_repository.dart';
import 'package:tv_monitor/features/presentation/services/playlist_controller_manager.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _deviceId;
  String? _accessToken;

  // Services
  late final WebSocketReconnectionService _wsReconnectionService;
  late final DeviceMemoryMonitor _memoryMonitor;
  late final AppStateManager _stateManager;
  late final BackgroundDownloadService _downloadService;
  late final WebSocketRepository _webSocketRepository;
  late final PlaylistControllerManager _controllerManager;

  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _downloadProgressSubscription;
  StreamSubscription? _videoBlocSubscription; // CRITICAL: Must dispose!
  Timer? _sendReadyPlaylistsTimer;
  DateTime? _lastReadyNotificationTime;

  // Pre-initialization state
  bool _isPreInitializing = false;
  Timer? _preInitDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize services
    _wsReconnectionService = sl<WebSocketReconnectionService>();
    _memoryMonitor = sl<DeviceMemoryMonitor>();
    _stateManager = sl<AppStateManager>();
    _downloadService = sl<BackgroundDownloadService>();
    _webSocketRepository = sl<WebSocketRepository>();
    _controllerManager = sl<PlaylistControllerManager>();

    // Listen to connectivity changes
    _listenToConnectivityChanges();

    // Listen to download progress
    _listenToDownloadProgress();

    _initializeApp();
  }

  void _initializeApp() async {
    AppLogger.info('🚀 [APP] HomeScreen initialization started');

    // Check if app needs synchronization after power/network loss
    if (_stateManager.needsSynchronization()) {
      AppLogger.info('🔄 [APP] App needs synchronization, restoring state...');
      await _restoreAppState();
    }

    if (!mounted) return;

    // Get device ID from local storage (already registered in LoadingScreen)
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final deviceLocalDataSource = sl<DeviceLocalDataSource>();
    final deviceId = await deviceLocalDataSource.getSavedDeviceId();
    _accessToken = await authLocalDataSource.getAccessToken();

    if (deviceId == null) {
      AppLogger.error('❌ [APP] No device ID found! This should not happen.');
      // Fallback: navigate back to loading screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoadingScreen()),
        );
      }
      return;
    }

    _deviceId = deviceId;
    AppLogger.info('✅ [APP] Device ID loaded: $deviceId');

    if (!mounted) return;

    // Check if playlists are already loaded from LoadingScreen
    final currentVideoState = context.read<VideoBloc>().state;
    AppLogger.info('📂 [APP] Current VideoBloc state: ${currentVideoState.runtimeType}');

    if (currentVideoState is VideoLoaded && currentVideoState.currentPlaylist != null) {
      // Playlists already loaded from LoadingScreen, no need to reload
      AppLogger.info('✅ [APP] Playlists already loaded with ${currentVideoState.playlists.length} playlists');
      AppLogger.info('   Current playlist: ${currentVideoState.currentPlaylist?.name}');
    } else {
      // Need to load playlists
      AppLogger.info('📂 [APP] Loading playlists from local database...');
      context.read<VideoBloc>().add(const LoadLocalPlaylists());

      // Wait for playlists to load
      await Future.delayed(const Duration(seconds: 1));
    }

    // WebSocket is already connected in LoadingScreen
    // Just verify and reconnect if needed
    AppLogger.info('🔌 [APP] Verifying WebSocket connection...');
    if (!_wsReconnectionService.isConnected) {
      AppLogger.info('⚠️ [APP] WebSocket not connected, reconnecting...');
      await _connectWebSocket(deviceId);
    } else {
      AppLogger.info('✅ [APP] WebSocket already connected from LoadingScreen');
    }

    // Start device memory monitoring
    _startMemoryMonitoring();

    // Mark synchronization as completed
    _stateManager.markSyncCompleted();

    if (!mounted) return;

    // Listen to video bloc to save state and handle WebSocket reloads
    // CRITICAL: Store subscription for proper disposal
    _videoBlocSubscription = context.read<VideoBloc>().stream.listen((videoState) {
      if (!mounted) return;

      if (videoState is VideoLoaded) {
        // Save current playback state
        _stateManager.savePlaybackState(
          playlistId: videoState.currentPlaylist?.id,
          mediaIndex: videoState.currentMediaIndex,
          isPlaying: videoState.isPlaying,
        );

        // CRITICAL: Check if this is a WebSocket reload using FLAG (not deviceScreens)
        // This happens ONLY after WebSocket reload_playlist command
        // Flag prevents false positives from other state changes
        if (videoState.isWebSocketReload) {
          // CRITICAL DEBUG: Log download trigger
          DownloadDebugLogger.logHomeScreenReceive(
            isWebSocketReload: true,
            playlistName: videoState.currentPlaylist?.name,
            willTriggerDownload: true,
          );

          AppLogger.info('🔄 [APP] WebSocket reload detected via flag - checking for downloads');
          _handleWebSocketReload(videoState);
        } else {
          // CRITICAL DEBUG: Log NO download
          DownloadDebugLogger.logHomeScreenReceive(
            isWebSocketReload: false,
            playlistName: videoState.currentPlaylist?.name,
            willTriggerDownload: false,
          );

          AppLogger.info('🔄 [APP] Local state change - NO download check');
        }

        // IMPORTANT: Only send ready playlist IDs when NO downloads are in progress
        // This prevents premature "ready" notifications while files are still downloading
        if (!_downloadService.hasDownloads) {
          AppLogger.info('✅ [APP] No downloads in progress, ready to notify backend');
          _sendReadyPlaylistIdsDebounced();
        } else {
          AppLogger.info('⏳ [APP] Downloads still in progress (active: ${_downloadService.isDownloading}, queue: ${_downloadService.queueSize}), delaying notification');
        }

        // PRE-INITIALIZE: Pre-initialize all ready playlists for fast switching
        // ONLY if NOT a WebSocket reload (to avoid interference with downloads)
        if (!videoState.isWebSocketReload) {
          _preInitializePlaylists(videoState, sequential: true);
        } else {
          AppLogger.info('⏸️ [APP] Skipping pre-init during WebSocket reload');
        }
      }
    });

    AppLogger.info('✅ [APP] HomeScreen initialization completed');
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // Check if any connection is available (not none)
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection) {
        AppLogger.info('📡 [APP] Internet connection restored, reconnecting...');
        _handleConnectivityRestored();
      }
    });
  }

  void _listenToDownloadProgress() {
    _downloadProgressSubscription = _downloadService.progressStream.listen((progress) {
      if (progress.status == DownloadStatus.downloading) {
        AppLogger.info('⬇️ [BACKGROUND] Downloading "${progress.playlist.name}": ${(progress.progress * 100).toStringAsFixed(1)}%');
      } else if (progress.status == DownloadStatus.completed && mounted) {
        AppLogger.info('✅ [BACKGROUND] Download completed: "${progress.playlist.name}"');
        AppLogger.info('🔄 [BACKGROUND] Reloading playlists to reflect new content (playback will continue)');

        // Use a small delay to ensure database is updated
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!mounted) return;

          // Reload local playlists WITHOUT stopping current playback
          // LoadLocalPlaylists preserves current state
          context.read<VideoBloc>().add(const LoadLocalPlaylists());

          // Wait for playlists to load
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // CRITICAL FIX: Only notify backend if ALL downloads are complete (queue is empty)
          // This prevents sending "ready" notifications while other playlists are still downloading
          if (!_downloadService.hasDownloads) {
            AppLogger.info('📤 [BACKGROUND] All downloads complete! Notifying backend of ready playlists');
            _sendReadyPlaylistIdsDebounced();
          } else {
            AppLogger.info('⏳ [BACKGROUND] More downloads in queue (${_downloadService.queueSize}), waiting before notification');
          }
        });
      } else if (progress.status == DownloadStatus.failed) {
        AppLogger.error('❌ [BACKGROUND] Download failed: "${progress.playlist.name}" - ${progress.error}');
      }
    });
  }

  void _handleWebSocketReload(VideoLoaded state) {
    // Called when playlists are loaded from server after WebSocket reload
    AppLogger.info('🔄 [APP] WebSocket reload completed, checking for new playlists to download');
    AppLogger.info('🎬 [APP] Current playback state preserved: playlist=${state.currentPlaylist?.name}, playing=${state.isPlaying}');

    // Start background download for any playlists that need updating
    _autoDownloadPlaylistsOnReload(state);
  }

  Future<void> _connectWebSocket(String deviceId) async {
    try {
      final authLocalDataSource = sl<AuthLocalDataSource>();
      final accessToken = await authLocalDataSource.getAccessToken();

      if (accessToken != null) {
        _accessToken = accessToken;

        // Use reconnection service for automatic reconnection
        await _wsReconnectionService.connect(deviceId: deviceId, accessToken: accessToken);

        if (mounted) {
          context.read<WebSocketBloc>().add(ConnectWebSocket(deviceId: deviceId, accessToken: accessToken));
        }

        AppLogger.info('✅ [APP] WebSocket connected with auto-reconnection');

        // IMPORTANT: After WebSocket connection, send ready playlist IDs to backend
        // Wait a bit to ensure WebSocket is fully established
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          AppLogger.info('📤 [APP] Sending ready playlists after WebSocket connection...');
          await _sendReadyPlaylistIds();
        }
      }
    } catch (e) {
      AppLogger.error('❌ [APP] Failed to connect WebSocket', e);
    }
  }

  void _startMemoryMonitoring() {
    // Register callback to provide ready playlist IDs
    _memoryMonitor.setReadyPlaylistIdsCallback(_getReadyPlaylistIdsForMemoryReport);

    // Start monitoring
    _memoryMonitor.startMonitoring();
    AppLogger.info('📊 [APP] Device memory monitoring started with ready playlists tracking');
  }

  /// Get ready playlist IDs for memory report
  /// This is called by DeviceMemoryMonitor every 60 seconds
  Future<List<int>> _getReadyPlaylistIdsForMemoryReport() async {
    try {
      if (!mounted) return [];

      final videoState = context.read<VideoBloc>().state;

      if (videoState is! VideoLoaded) {
        return [];
      }

      // Collect ready playlist IDs
      final readyPlaylistIds = <int>[];

      for (final playlist in videoState.playlists) {
        if (playlist.status.isReady && playlist.status.allDownloaded) {
          final allMediaDownloaded = playlist.mediaItems.every((item) => item.downloaded == true);
          if (allMediaDownloaded) {
            readyPlaylistIds.add(playlist.id);
          }
        }
      }

      return readyPlaylistIds;
    } catch (e) {
      AppLogger.error('❌ [APP] Error getting ready playlist IDs for memory report', e);
      return [];
    }
  }

  void _autoDownloadPlaylistsOnReload(VideoLoaded state) {
    // This is only called after WebSocket reload_playlist command
    // Download ALL playlists in background (including current one) WITHOUT stopping playback
    AppLogger.info('🔍 [APP] Analyzing ${state.playlists.length} playlists for background download...');

    final playlistsToDownload = state.playlists.where((playlist) {
      AppLogger.info('   📋 Checking playlist "${playlist.name}": isReady=${playlist.status.isReady}, allDownloaded=${playlist.status.allDownloaded}');

      // If not ready at all, definitely need to download
      if (!playlist.status.isReady) {
        AppLogger.info('   ⬇️ Needs download: "${playlist.name}" - not ready');
        return true;
      }

      // If ready but not all downloaded, need to verify
      if (!playlist.status.allDownloaded) {
        AppLogger.info('   ⬇️ Needs download: "${playlist.name}" - not all downloaded');
        return true;
      }

      // Check if any media items are not downloaded
      final hasUndownloadedMedia = playlist.mediaItems.any((item) => item.downloaded != true);
      if (hasUndownloadedMedia) {
        AppLogger.info('   ⬇️ Needs download: "${playlist.name}" - has undownloaded media');
        return true;
      }

      // Playlist is fully ready, skip
      AppLogger.info('   ✅ Already downloaded: "${playlist.name}"');
      return false;
    }).toList();

    if (playlistsToDownload.isNotEmpty) {
      // Sort playlists: current playlist first (to minimize disruption), then others
      playlistsToDownload.sort((a, b) {
        final aIsCurrent = state.currentPlaylist != null && a.id == state.currentPlaylist!.id;
        final bIsCurrent = state.currentPlaylist != null && b.id == state.currentPlaylist!.id;
        if (aIsCurrent) return -1;
        if (bIsCurrent) return 1;
        return 0;
      });

      final currentPlaylistNeedsDownload = playlistsToDownload.isNotEmpty &&
          state.currentPlaylist != null &&
          playlistsToDownload.first.id == state.currentPlaylist!.id;

      if (currentPlaylistNeedsDownload) {
        AppLogger.info('⚠️ [APP] Current playing playlist needs update, will download in background');
      }

      AppLogger.info('📥 [APP] WebSocket reload: Starting background download for ${playlistsToDownload.length} playlists');
      AppLogger.info('   🎬 Video playback will continue uninterrupted');
      _downloadService.enqueueMultiple(playlistsToDownload);
    } else {
      AppLogger.info('✅ [APP] All playlists already fully downloaded, no action needed');
    }
  }

  Future<void> _restoreAppState() async {
    final savedState = await _stateManager.restorePlaybackState();

    if (savedState != null) {
      final playlistId = savedState['playlist_id'] as int;
      final mediaIndex = savedState['media_index'] as int;
      final isPlaying = savedState['is_playing'] as bool;

      AppLogger.info('🔄 [APP] Restoring playback: playlist=$playlistId, index=$mediaIndex, playing=$isPlaying');

      // Wait for playlists to load, then restore state
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        context.read<VideoBloc>().add(SelectPlaylist(playlistId: playlistId));
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && isPlaying) {
        context.read<VideoBloc>().add(PlayVideo(index: mediaIndex));
      }
    }

    // Upload pending screenshots
    await _uploadPendingScreenshots();
  }

  Future<void> _uploadPendingScreenshots() async {
    // TODO: Implement screenshot upload from pending list
    final pending = _stateManager.getPendingScreenshots();
    if (pending.isNotEmpty) {
      AppLogger.info('📸 [APP] Found ${pending.length} pending screenshots to upload');
      // Implementation would go here
    }
  }

  /// Debounced version of _sendReadyPlaylistIds to avoid sending too frequently
  /// Waits 2 seconds after last call before actually sending
  void _sendReadyPlaylistIdsDebounced() {
    // Cancel previous timer if exists
    _sendReadyPlaylistsTimer?.cancel();

    // Set new timer
    _sendReadyPlaylistsTimer = Timer(const Duration(seconds: 2), () {
      _sendReadyPlaylistIds();
    });
  }

  /// Send ready playlist IDs to backend via WebSocket
  /// This notifies the backend which playlists are fully downloaded and ready on this device
  Future<void> _sendReadyPlaylistIds() async {
    try {
      AppLogger.info('📡 [READY_CHECK] Starting ready playlists notification...');

      // Check if WebSocket is connected first
      final isConnectedResult = await _webSocketRepository.isConnected;

      final isConnected = isConnectedResult.fold(
        (failure) => false,
        (connected) => connected,
      );

      if (!isConnected) {
        AppLogger.info('⚠️ [READY_CHECK] WebSocket not connected, skipping notification');
        return;
      }

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // RATE LIMITING: Prevent sending notifications too frequently
      if (_lastReadyNotificationTime != null) {
        final elapsed = DateTime.now().difference(_lastReadyNotificationTime!);
        const minimumInterval = Duration(seconds: 10);

        if (elapsed < minimumInterval) {
          final remainingSeconds = (minimumInterval - elapsed).inSeconds;
          AppLogger.info('⏱️ [READY_CHECK] Rate limited - sent ${elapsed.inSeconds}s ago, waiting ${remainingSeconds}s more');
          return;
        }
      }

      // Get current video state
      final videoState = context.read<VideoBloc>().state;

      if (videoState is! VideoLoaded) {
        AppLogger.info('⚠️ [READY_CHECK] VideoBloc not loaded yet, skipping notification');
        return;
      }

      // Collect all ready playlist IDs
      final readyPlaylistIds = <int>[];

      AppLogger.info('🔍 [READY_CHECK] Checking ${videoState.playlists.length} playlists...');

      for (final playlist in videoState.playlists) {
        // Check if playlist is fully ready
        if (playlist.status.isReady && playlist.status.allDownloaded) {
          // Double check all media items are downloaded
          final allMediaDownloaded = playlist.mediaItems.every((item) => item.downloaded == true);

          if (allMediaDownloaded) {
            readyPlaylistIds.add(playlist.id);
            AppLogger.info('   ✅ Ready: "${playlist.name}" (ID: ${playlist.id})');
          } else {
            AppLogger.info('   ⏳ Not fully downloaded: "${playlist.name}"');
          }
        } else {
          AppLogger.info('   ⏳ Not ready: "${playlist.name}" (isReady: ${playlist.status.isReady}, allDownloaded: ${playlist.status.allDownloaded})');
        }
      }

      if (readyPlaylistIds.isEmpty) {
        AppLogger.info('⚠️ [READY_CHECK] No ready playlists found to notify backend');
        return;
      }

      // Send to backend via WebSocket
      final message = {
        'type': 'ready_playlists',
        'playlist_ids': readyPlaylistIds,
      };

      AppLogger.info('📤 [READY_CHECK] Sending ${readyPlaylistIds.length} ready playlist IDs to backend: $readyPlaylistIds');

      final result = await _webSocketRepository.sendMessage(message);

      result.fold(
        (failure) {
          AppLogger.error('❌ [READY_CHECK] Failed to send: ${failure.message}');
        },
        (_) {
          _lastReadyNotificationTime = DateTime.now();
          AppLogger.info('✅ [READY_CHECK] Successfully notified backend about ${readyPlaylistIds.length} ready playlists');
        },
      );
    } catch (e) {
      AppLogger.error('❌ [READY_CHECK] Exception occurred', e);
    }
  }

  void _handleConnectivityRestored() async {
    // Reconnect WebSocket
    if (_deviceId != null && _accessToken != null) {
      await _wsReconnectionService.reconnectNow();

      // Note: Don't reload playlists automatically to avoid re-downloading videos
      // Playlists will only be reloaded via WebSocket reload_playlist command
    }

    // Upload pending screenshots
    await _uploadPendingScreenshots();

    // Mark sync as completed
    _stateManager.markSyncCompleted();
  }

  /// Pre-initialize all ready playlists for fast switching
  /// This is called whenever playlists change
  /// DEBOUNCED and runs in BACKGROUND to not block UI
  ///
  /// @param sequential - If true, initializes playlists one by one for stability
  void _preInitializePlaylists(VideoLoaded state, {bool sequential = true}) {
    // DEBOUNCE: Cancel previous timer to avoid multiple rapid calls
    _preInitDebounceTimer?.cancel();

    // Wait 500ms before starting to avoid rapid consecutive calls
    _preInitDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _executePreInitialization(state, sequential: sequential);
    });
  }

  /// Execute pre-initialization in background (non-blocking)
  Future<void> _executePreInitialization(VideoLoaded state, {bool sequential = true}) async {
    // Check if already initializing
    if (_isPreInitializing) {
      AppLogger.info('⚠️ [PRE_INIT] Already initializing, skipping...');
      return;
    }

    AppLogger.info('🎬 [PRE_INIT] Starting pre-initialization for ${state.playlists.length} playlists (${sequential ? 'SEQUENTIAL' : 'PARALLEL'})');

    // Filter only ready playlists
    final readyPlaylists = state.playlists.where((p) {
      return p.status.isReady &&
          p.status.allDownloaded &&
          p.mediaItems.isNotEmpty &&
          p.mediaItems.every((m) => m.downloaded == true && m.localPath != null);
    }).toList();

    AppLogger.info('🎬 [PRE_INIT] ${readyPlaylists.length} playlists are ready for pre-initialization');

    if (readyPlaylists.isEmpty) {
      AppLogger.info('⚠️ [PRE_INIT] No ready playlists to pre-initialize');
      return;
    }

    if (!mounted) {
      AppLogger.info('⚠️ [PRE_INIT] Widget not mounted, skipping pre-initialization');
      return;
    }

    // Set flag to prevent concurrent initializations
    _isPreInitializing = true;

    try {
      // CRITICAL: Prioritize current playlist for initialization first
      // This ensures the current playlist is ready immediately for playback
      if (state.currentPlaylist != null) {
        final currentId = state.currentPlaylist!.id;
        readyPlaylists.sort((a, b) {
          if (a.id == currentId) return -1;
          if (b.id == currentId) return 1;
          return 0;
        });
        AppLogger.info('🎯 [PRE_INIT] Current playlist (${state.currentPlaylist!.name}) will be initialized FIRST');
      }

      // Start pre-initialization (SEQUENTIAL for stability)
      final startTime = DateTime.now();

      // IMPORTANT: Run in background without blocking UI
      // Use unawaited to make this truly non-blocking
      _controllerManager.preInitializePlaylists(
        readyPlaylists,
        context,
        sequential: sequential,
      ).then((_) async {
        // Wait for ALL playlists to be ready for instant switching
        final playlistIds = readyPlaylists.map((p) => p.id).toList();
        AppLogger.info('⏳ [PRE_INIT] Waiting for ${playlistIds.length} playlists to be fully ready...');

        // Wait with timeout (30 seconds total)
        await _controllerManager.waitForAllPlaylistsReady(
          playlistIds,
          timeout: const Duration(seconds: 30),
        );

        if (mounted) {
          final elapsed = DateTime.now().difference(startTime);
          final stats = _controllerManager.getStats();
          AppLogger.info('✅ [PRE_INIT] Pre-initialization complete in ${elapsed.inMilliseconds}ms!');
          AppLogger.info('📊 [PRE_INIT] Stats: $stats');
          AppLogger.info('⚡ [PRE_INIT] All playlists are now ready for INSTANT switching!');
        }
      }).catchError((error) {
        AppLogger.error('❌ [PRE_INIT] Error during pre-initialization', error);
      }).whenComplete(() {
        // Reset flag when done
        _isPreInitializing = false;
      });
    } catch (e) {
      AppLogger.error('❌ [PRE_INIT] Exception during pre-initialization', e);
      _isPreInitializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App resumed, check connectivity and reconnect WebSocket only
      AppLogger.info('🔄 [APP] App resumed, checking connectivity...');
      _wsReconnectionService.checkConnectionHealth();

      // Only reconnect WebSocket, don't reload playlists
      if (_deviceId != null && _accessToken != null) {
        _wsReconnectionService.reconnectNow();
      }
    } else if (state == AppLifecycleState.paused) {
      // Save current state when app goes to background
      AppLogger.info('⏸️ [APP] App paused, saving state...');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cancel all subscriptions - CRITICAL for preventing memory leaks
    _connectivitySubscription?.cancel();
    _downloadProgressSubscription?.cancel();
    _videoBlocSubscription?.cancel(); // CRITICAL: Dispose VideoBloc listener

    // Cancel all timers
    _sendReadyPlaylistsTimer?.cancel();
    _preInitDebounceTimer?.cancel();

    // Stop services
    _memoryMonitor.stopMonitoring();

    // Dispose all pre-initialized controllers
    _controllerManager.disposeAll();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<VideoBloc, VideoState>(
        listener: (context, state) {
          if (state is VideoError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 20),
                  Text('Loading videos...', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            );
          }

          if (state is PlaylistDownloading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: state.progress, color: Colors.cyanAccent, strokeWidth: 6),
                  const SizedBox(height: 20),
                  Text(
                    'Downloading playlist: ${state.playlist.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${state.downloadedItems}/${state.totalItems} items',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  if (state.currentMediaName != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Current: ${state.currentMediaName}',
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ],
              ),
            );
          }

          if (state is VideoLoaded) {
            // Check if current playlist exists
            if (state.currentPlaylist == null || state.currentPlaylist!.mediaItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.video_library_outlined, size: 80, color: Colors.white54),
                    const SizedBox(height: 20),
                    const Text('No playlist available', style: TextStyle(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 10),
                    const Text(
                      'Please add playlists from the admin panel',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Show video player (downloads completed in LoadingScreen)
            return VideoPlayerWidget(
              playlist: state.currentPlaylist!,
              currentMediaIndex: state.currentMediaIndex,
              deviceId: _deviceId ?? '',
              textOverlayConfig: state.textOverlayConfig,
              brightness: state.brightness,
              volume: state.volume,
            );
          }

          if (state is VideoError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_deviceId != null) {
                        context.read<VideoBloc>().add(LoadDeviceScreens(deviceId: _deviceId!));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Initializing...', style: TextStyle(color: Colors.white, fontSize: 18)),
          );
        },
      ),
    );
  }
}
