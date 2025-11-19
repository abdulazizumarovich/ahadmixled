import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/presentation/blocs/device/device_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/video/video_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/websocket/websocket_bloc.dart';
import 'package:tv_monitor/features/presentation/screens/home_screen.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/data/datasources/local/auth_local_datasource.dart';
import 'package:tv_monitor/features/data/services/websocket_reconnection_service.dart';
import 'package:tv_monitor/injection_container.dart';

/// **LoadingScreen - Pre-Download & Initialization**
///
/// This screen ensures ALL playlists and their media are fully downloaded
/// BEFORE allowing playback to begin. This is critical for a seamless user
/// experience and prevents playback issues.
///
/// **Complete Application Flow:**
///
/// 1. **Authentication** (prior to this screen)
///    - User logs in via AuthBloc
///    - Access token and refresh token obtained
///
/// 2. **Device Registration** (this screen - step 1)
///    - Collect device information (model, OS, screen size, etc.)
///    - Register device with backend server
///    - Receive unique device_id
///
/// 3. **Playlist Loading** (this screen - step 2)
///    - Fetch all playlists assigned to this device from server
///    - Server returns playlist metadata with media items
///
/// 4. **CRITICAL: Pre-Download All Media** (this screen - step 3)
///    - Download ALL media files for ALL playlists sequentially
///    - Verify each file exists on disk after download
///    - Show real-time progress to user
///    - **IMPORTANT:** WebSocket notifications sent during download:
///      * 'downloading': Progress updates
///      * 'ready': Playlist fully downloaded and ready for playback
///      * 'failed': Download errors occurred
///
/// 5. **Validation** (this screen - step 4)
///    - Verify all playlists have status.isReady = true
///    - Verify all playlists have status.allDownloaded = true
///    - Verify all media items have downloaded = true
///    - Verify all media files exist on disk
///
/// 6. **Navigation to HomeScreen** (only after ALL above complete)
///    - Navigate to HomeScreen ONLY when ALL playlists ready
///    - HomeScreen displays video player with fully downloaded content
///
/// **Why This Approach?**
/// - Prevents "file not found" errors during playback
/// - Ensures smooth transitions between media items
/// - Provides clear feedback to user about download progress
/// - Backend server knows exactly when device is ready via WebSocket
///
/// **WebSocket Notification Format:**
/// ```json
/// {
///   "type": "playlist_status",
///   "playlist_id": 123,
///   "status": "ready",
///   "total_items": 10,
///   "downloaded_items": 10
/// }
/// ```
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = 'Initializing...';
  int _totalMediaItems = 0;
  int _downloadedMediaItems = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  void _startInitialization() async {
    setState(() {
      _statusMessage = 'Getting device information...';
    });

    // Start device registration
    context.read<DeviceBloc>().add(const GetDeviceInfo());
  }

  void _onDeviceInfoLoaded() {
    setState(() {
      _statusMessage = 'Registering device...';
    });
  }

  void _onDeviceRegistered(String deviceId) async {
    setState(() {
      _statusMessage = 'Connecting to server...';
    });

    // CRITICAL: Connect WebSocket BEFORE loading playlists
    // This ensures WebSocket is ready to receive download progress notifications
    await _connectWebSocket(deviceId);

    if (!mounted) return;

    setState(() {
      _statusMessage = 'Loading playlists from server...';
    });

    // Load device screens and playlists
    context.read<VideoBloc>().add(LoadDeviceScreens(deviceId: deviceId));
  }

  /// Connect to WebSocket before downloading
  Future<void> _connectWebSocket(String deviceId) async {
    try {
      AppLogger.info('🔌 [LOADING] Connecting to WebSocket before download...');

      final authLocalDataSource = sl<AuthLocalDataSource>();
      final accessToken = await authLocalDataSource.getAccessToken();

      if (accessToken != null) {
        // Use reconnection service for automatic reconnection
        final wsReconnectionService = sl<WebSocketReconnectionService>();
        await wsReconnectionService.connect(deviceId: deviceId, accessToken: accessToken);

        if (mounted) {
          context.read<WebSocketBloc>().add(ConnectWebSocket(deviceId: deviceId, accessToken: accessToken));
        }

        // Wait a bit to ensure WebSocket is fully established
        await Future.delayed(const Duration(seconds: 1));

        AppLogger.info('✅ [LOADING] WebSocket connected and ready for download notifications');
      } else {
        AppLogger.error('❌ [LOADING] No access token available for WebSocket connection');
      }
    } catch (e) {
      AppLogger.error('❌ [LOADING] Failed to connect WebSocket', e);
      // Continue anyway - download can proceed without WebSocket
    }
  }

  void _onPlaylistsLoaded(List<PlaylistEntity> playlists) async {
    if (playlists.isEmpty) {
      AppLogger.error('❌ [LOADING] No playlists available from server');
      setState(() {
        _statusMessage = 'No playlists available.\nPlease configure playlists in admin panel.';
      });
      return;
    }

    // Calculate total media items across ALL playlists
    _totalMediaItems = playlists.fold(0, (sum, playlist) => sum + playlist.mediaItems.length);

    AppLogger.info('📥 [LOADING] Found ${playlists.length} playlists with $_totalMediaItems total media items');

    setState(() {
      _statusMessage = 'Verifying downloaded files...';
    });

    // STRICT VALIDATION: Check which playlists need downloading (WITH FILE EXISTENCE CHECK)
    final List<PlaylistEntity> playlistsToDownload = [];

    for (final playlist in playlists) {
      // Check playlist status
      if (!playlist.status.isReady || !playlist.status.allDownloaded) {
        AppLogger.info('📥 [LOADING] Playlist "${playlist.name}" not ready (status: ${playlist.status.isReady}, allDownloaded: ${playlist.status.allDownloaded})');
        playlistsToDownload.add(playlist);
        continue;
      }

      // Verify each media item is actually downloaded
      final hasUndownloadedMedia = playlist.mediaItems.any((item) => item.downloaded != true);
      if (hasUndownloadedMedia) {
        AppLogger.info('📥 [LOADING] Playlist "${playlist.name}" has undownloaded media items');
        playlistsToDownload.add(playlist);
        continue;
      }

      // CRITICAL: Check if files actually exist on disk
      bool missingFiles = false;
      for (final item in playlist.mediaItems) {
        if (item.localPath == null || item.localPath!.isEmpty) {
          AppLogger.info('📥 [LOADING] Playlist "${playlist.name}" has media without local path: ${item.mediaName}');
          missingFiles = true;
          break;
        }

        // Check file existence
        final file = File(item.localPath!);
        if (!await file.exists()) {
          AppLogger.info('📥 [LOADING] Playlist "${playlist.name}" - File not found: ${item.mediaName} at ${item.localPath}');
          missingFiles = true;
          break;
        }
      }

      if (missingFiles) {
        playlistsToDownload.add(playlist);
        continue;
      }

      AppLogger.info('✅ [LOADING] Playlist "${playlist.name}" is fully downloaded and verified');
    }

    // Calculate how many playlists are already ready
    final readyCount = playlists.length - playlistsToDownload.length;

    // If we have at least ONE ready playlist, we can proceed
    // The rest will download in background via BackgroundDownloadService in HomeScreen
    // IMPORTANT: HomeScreen will only send "ready" notification when ALL downloads complete
    if (readyCount > 0) {
      AppLogger.info('✅ [LOADING] $readyCount/${playlists.length} playlists ready, proceeding to HomeScreen');
      if (playlistsToDownload.isNotEmpty) {
        AppLogger.info('📥 [LOADING] ${playlistsToDownload.length} playlists will download in background');
      }

      setState(() {
        _statusMessage = '✓ $readyCount/${playlists.length} playlists ready\n\nStarting player...';
      });

      // Small delay to show message
      await Future.delayed(const Duration(milliseconds: 500));

      // CRITICAL: Reload local playlists to ensure VideoBloc has fresh data
      AppLogger.info('🔄 [LOADING] Loading playlists into VideoBloc...');
      if (mounted) {
        context.read<VideoBloc>().add(const LoadLocalPlaylists());

        // Wait for playlists to load
        await Future.delayed(const Duration(seconds: 1));

        // Verify playlists are loaded
        if (mounted) {
          final videoState = context.read<VideoBloc>().state;
          if (videoState is VideoLoaded && videoState.currentPlaylist != null) {
            AppLogger.info('✅ [LOADING] VideoBloc ready with playlist: ${videoState.currentPlaylist?.name}');
          } else {
            AppLogger.error('⚠️ [LOADING] Warning: VideoBloc state is: ${videoState.runtimeType}');
          }
        }
      }

      // Navigate immediately - background download will handle the rest
      _navigateToHome();
      return;
    }

    // If NO playlists are ready, we MUST download at least one
    if (playlistsToDownload.isEmpty) {
      AppLogger.info('✅ [LOADING] All ${playlists.length} playlists verified and ready');
      _navigateToHome();
      return;
    }

    AppLogger.info('📥 [LOADING] Need to download ${playlistsToDownload.length}/${playlists.length} playlists');

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Preparing downloads...\n${playlistsToDownload.length} playlists need downloading';
    });

    // Download ALL playlists before proceeding
    await _downloadAllPlaylists(playlistsToDownload);
  }


  Future<void> _downloadAllPlaylists(List<PlaylistEntity> playlists) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> failedPlaylists = [];

    AppLogger.info('📥 [LOADING] Starting download of ${playlists.length} playlists...');

    for (int i = 0; i < playlists.length; i++) {
      final playlist = playlists[i];

      setState(() {
        _statusMessage =
            'Downloading: ${playlist.name}\n(${i + 1}/${playlists.length} playlists)\n\nProgress: $_downloadedMediaItems / $_totalMediaItems items';
      });

      AppLogger.info('📥 [LOADING] [${i + 1}/${playlists.length}] Starting download: "${playlist.name}" (${playlist.mediaItems.length} items)');

      try {
        // Download playlist and wait for completion
        final success = await _downloadPlaylist(playlist);

        if (success) {
          successCount++;
          AppLogger.info('✅ [LOADING] [${i + 1}/${playlists.length}] Completed: "${playlist.name}"');
        } else {
          failedCount++;
          failedPlaylists.add(playlist.name);
          AppLogger.error('❌ [LOADING] [${i + 1}/${playlists.length}] Failed: "${playlist.name}"');
        }
      } catch (e) {
        failedCount++;
        failedPlaylists.add(playlist.name);
        AppLogger.error('❌ [LOADING] [${i + 1}/${playlists.length}] Exception downloading "${playlist.name}": $e');
      }

      // Small delay between playlists to avoid overwhelming the system
      if (i < playlists.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // All downloads completed - show summary
    AppLogger.info('✅ [LOADING] Download process completed:');
    AppLogger.info('   ✓ Successful: $successCount/${playlists.length}');
    AppLogger.info('   ✗ Failed: $failedCount/${playlists.length}');

    if (failedPlaylists.isNotEmpty) {
      AppLogger.error('   Failed playlists: ${failedPlaylists.join(", ")}');
    }

    // Show completion message
    setState(() {
      _isDownloading = false;
      _statusMessage = successCount == playlists.length
          ? 'All playlists downloaded successfully!\n✓ $successCount/${ playlists.length} playlists ready\n\nInitializing playback...'
          : 'Download completed with warnings\n✓ $successCount/${playlists.length} successful\n✗ $failedCount failed\n\nPreparing to start...';
    });

    // CRITICAL: Reload local playlists to ensure VideoBloc has fresh data
    AppLogger.info('🔄 [LOADING] Reloading local playlists before navigating to HomeScreen...');
    if (mounted) {
      context.read<VideoBloc>().add(const LoadLocalPlaylists());

      // Wait for playlists to load
      await Future.delayed(const Duration(seconds: 2));

      // Verify playlists are loaded
      if (mounted) {
        final videoState = context.read<VideoBloc>().state;
        if (videoState is VideoLoaded && videoState.currentPlaylist != null) {
          AppLogger.info('✅ [LOADING] Playlists loaded successfully, ready to navigate');
        } else {
          AppLogger.error('⚠️ [LOADING] Warning: VideoBloc state is not ready: ${videoState.runtimeType}');
        }
      }
    }

    // Small delay to show completion message
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate to home screen
    _navigateToHome();
  }

  Future<bool> _downloadPlaylist(PlaylistEntity playlist) async {
    final completer = Completer<bool>();
    StreamSubscription? subscription;

    try {
      // Set timeout for download (10 minutes max)
      final timeout = Duration(minutes: 10);
      final totalItemsInPlaylist = playlist.mediaItems.length;

      AppLogger.info('📤 [LOADING] Starting download for "${playlist.name}" with $totalItemsInPlaylist items');

      // Track previous downloaded count for this playlist
      int previousDownloadedCount = 0;

      // Listen to video bloc state changes
      subscription = context.read<VideoBloc>().stream.listen((state) {
        if (state is PlaylistDownloading && state.playlist.id == playlist.id) {
          // Update UI with download progress
          if (mounted) {
            // Calculate increment since last update
            final increment = state.downloadedItems - previousDownloadedCount;
            if (increment > 0) {
              _downloadedMediaItems += increment;
              previousDownloadedCount = state.downloadedItems;
            }

            setState(() {
              final percentage = state.totalItems > 0 ? (state.downloadedItems / state.totalItems * 100).toStringAsFixed(1) : '0';
              _statusMessage =
                  'Downloading: ${playlist.name}\n${state.downloadedItems}/${state.totalItems} items ($percentage%)\n\n${state.currentMediaName ?? ''}';
            });
          }

          // Check if ALL items in THIS playlist are downloaded
          if (state.downloadedItems >= state.totalItems && !completer.isCompleted) {
            AppLogger.info('✅ [LOADING] Playlist "${playlist.name}" download completed: ${state.downloadedItems}/${state.totalItems} items');
            completer.complete(true);
          }
        } else if (state is VideoLoaded && !completer.isCompleted) {
          // Check if this playlist is now fully downloaded in the loaded state
          final loadedPlaylist = state.playlists.firstWhere(
            (p) => p.id == playlist.id,
            orElse: () => playlist,
          );

          if (loadedPlaylist.status.allDownloaded) {
            AppLogger.info('✅ [LOADING] Playlist "${playlist.name}" confirmed ready via VideoLoaded state');
            completer.complete(true);
          }
        } else if (state is VideoError && !completer.isCompleted) {
          // Download failed
          AppLogger.error('❌ [LOADING] Playlist "${playlist.name}" download failed: ${state.message}');
          completer.complete(false);
        }
      });

      // Start download
      AppLogger.info('📤 [LOADING] Dispatching DownloadPlaylist event for: ${playlist.name}');
      context.read<VideoBloc>().add(DownloadPlaylist(playlist: playlist));

      // Wait for download to complete with timeout
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          AppLogger.error('⏱️ [LOADING] Download timeout for playlist: ${playlist.name}');
          return false;
        },
      );

      return result;
    } catch (e) {
      AppLogger.error('❌ [LOADING] Exception in _downloadPlaylist: $e');
      return false;
    } finally {
      // Always cancel subscription
      await subscription?.cancel();
    }
  }

  void _navigateToHome() async {
    AppLogger.info('✅ [LOADING] Preparing to navigate to HomeScreen...');

    // Small delay to ensure playlists are loaded in VideoBloc
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    AppLogger.info('🚀 [LOADING] Navigating to HomeScreen');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceBloc, DeviceState>(
      listener: (context, deviceState) {
        if (deviceState is DeviceInfoLoaded) {
          _onDeviceInfoLoaded();
          context.read<DeviceBloc>().add(RegisterDevice(deviceInfo: deviceState.deviceInfo));
        } else if (deviceState is DeviceRegistered) {
          _onDeviceRegistered(deviceState.deviceId);
        }
      },
      child: BlocListener<VideoBloc, VideoState>(
        listener: (context, videoState) {
          if (videoState is VideoLoaded && !_isDownloading) {
            // Initial playlists loaded from server
            _onPlaylistsLoaded(videoState.playlists);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tv, size: 100, color: Colors.cyanAccent.shade700),
                  const SizedBox(height: 40),
                  const Text(
                    'AdPlayer',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text('TV Monitor System', style: TextStyle(fontSize: 20, color: Colors.white70)),
                  const SizedBox(height: 60),
                  CircularProgressIndicator(
                    value: _totalMediaItems > 0 ? _downloadedMediaItems / _totalMediaItems : null,
                    color: Colors.cyanAccent.shade700,
                    strokeWidth: 6,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  if (_totalMediaItems > 0 && _isDownloading) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Progress: $_downloadedMediaItems / $_totalMediaItems items',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _downloadedMediaItems / _totalMediaItems,
                      backgroundColor: Colors.white24,
                      color: Colors.cyanAccent.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
