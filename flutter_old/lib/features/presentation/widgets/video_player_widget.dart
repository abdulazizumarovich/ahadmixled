import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';
import 'package:tv_monitor/features/presentation/blocs/video/video_bloc.dart';
import 'package:tv_monitor/features/presentation/widgets/text_overlay_widget.dart';
import 'package:tv_monitor/features/presentation/services/playlist_controller_manager.dart';
import 'package:tv_monitor/injection_container.dart';

class VideoPlayerWidget extends StatefulWidget {
  final PlaylistEntity playlist;
  final int currentMediaIndex;
  final String deviceId;
  final TextOverlayConfig? textOverlayConfig;
  final int brightness;
  final int volume;

  const VideoPlayerWidget({
    super.key,
    required this.playlist,
    required this.currentMediaIndex,
    required this.deviceId,
    this.textOverlayConfig,
    this.brightness = 50,
    this.volume = 50,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  // Controller manager for fast playlist switching
  late final PlaylistControllerManager _controllerManager;

  // Current playlist tracking
  PlaylistEntity? _previousPlaylist;
  bool _usedPreInitializedController = false;

  // Current media controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  int _currentIndex = 0;
  int _playCount = 0;
  String? _errorMessage;
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;

  // Image display state
  bool _isImage = false;
  Timer? _imageDisplayTimer;
  bool _isPlaying = true;
  double _imageProgress = 0.0;
  Timer? _imageProgressTimer;
  int _imageRemainingSeconds = 0;

  // Preloading - next media
  VideoPlayerController? _nextVideoPlayerController;
  bool _nextIsImage = false;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _controllerManager = sl<PlaylistControllerManager>();
    _previousPlaylist = widget.playlist;
    _currentIndex = widget.currentMediaIndex;
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if playlist changed (including reload of same playlist)
    final playlistChanged = oldWidget.playlist.id != widget.playlist.id;
    final playlistReloaded = oldWidget.playlist.id == widget.playlist.id &&
                             oldWidget.playlist.mediaItems.length != widget.playlist.mediaItems.length;

    // CRITICAL FIX: Also check if same playlist but media index reset to 0 (restart scenario)
    final samePlaylistRestart = oldWidget.playlist.id == widget.playlist.id &&
                                oldWidget.currentMediaIndex != 0 &&
                                widget.currentMediaIndex == 0;

    if (playlistChanged || playlistReloaded || samePlaylistRestart) {
      if (playlistChanged) {
        debugPrint('🔄 [FAST_SWITCH] Playlist changed from ${oldWidget.playlist.id} to ${widget.playlist.id}');
      } else if (playlistReloaded) {
        debugPrint('🔄 [RELOAD] Playlist ${widget.playlist.id} reloaded (media count changed)');
      } else if (samePlaylistRestart) {
        debugPrint('🔄 [RESTART] Same playlist ${widget.playlist.id} restarting from beginning');
      }

      // ALWAYS clear image cache when playlist changes or reloads to avoid stale images
      _controllerManager.clearImageCache(oldWidget.playlist.id);
      if (playlistChanged) {
        _controllerManager.clearImageCache(widget.playlist.id);
      }

      // Return the old controller to the manager for re-initialization
      // ONLY if it's a different playlist or reload (not a simple restart)
      if ((playlistChanged || playlistReloaded) && _previousPlaylist != null && !_usedPreInitializedController) {
        // Only return if we didn't use a pre-initialized controller
        // (if we did, it was already removed from the pool)
        debugPrint('📥 [FAST_SWITCH] Returning old controller to manager for re-init');
        _controllerManager.returnController(
          oldWidget.playlist.id,
          oldWidget.playlist,
          context,
        );
      }

      _previousPlaylist = widget.playlist;
      _currentIndex = widget.currentMediaIndex;
      _playCount = 0;
      _usedPreInitializedController = false;
      _initializePlayer();
      return;
    }

    // Check if media index changed
    if (oldWidget.currentMediaIndex != widget.currentMediaIndex) {
      debugPrint('🔄 Media index changed to ${widget.currentMediaIndex}, reinitializing player');
      _currentIndex = widget.currentMediaIndex;
      _playCount = 0;
      _initializePlayer();
    }
  }

  void _initializePlayer() async {
    if (widget.playlist.mediaItems.isEmpty) return;

    final currentMedia = widget.playlist.mediaItems[_currentIndex];

    // Check if media is downloaded
    if (!currentMedia.downloaded || currentMedia.localPath == null) {
      debugPrint('⏭️ Media not downloaded yet: ${currentMedia.mediaName}, skipping to next...');
      // Skip to next media that is downloaded
      _playNextDownloadedVideo();
      return;
    }

    final mediaUrl = currentMedia.localPath!;
    final file = File(mediaUrl);

    // Check if file exists
    if (!await file.exists()) {
      debugPrint('❌ File not found at: $mediaUrl');
      debugPrint('🔄 Triggering automatic re-download...');

      // Trigger automatic re-download
      if (mounted) {
        context.read<VideoBloc>().add(RedownloadMediaItem(mediaIndex: _currentIndex));
      }

      setState(() {
        _errorMessage = 'Media file not found. Re-downloading...';
      });
      return;
    }

    final fileSize = await file.length();
    debugPrint('✅ File exists! Size: $fileSize bytes');
    debugPrint('📂 Loading ${currentMedia.mediaType}: ${currentMedia.mediaName}');

    // Dispose old controllers and timers
    _disposeCurrentMedia();

    // Reset error message
    _errorMessage = null;

    try {
      if (currentMedia.mediaType == 'image') {
        // Handle IMAGE display
        await _initializeImage(currentMedia, file);
      } else if (currentMedia.mediaType == 'video') {
        // Handle VIDEO playback
        await _initializeVideo(currentMedia, file);
      } else {
        debugPrint('⏭️ Unsupported media type: ${currentMedia.mediaType}');
        _playNextVideo();
        return;
      }

      // Capture screenshot on start
      _captureScreenshot();

      // Start auto-hide timer for controls
      _startHideControlsTimer();

      // Preload next media
      _preloadNextMedia();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error initializing media player: $e');
      setState(() {
        _errorMessage = 'Failed to play media: ${currentMedia.mediaName}\nError: $e';
      });
    }
  }

  Future<void> _preloadNextMedia() async {
    if (_isPreloading || widget.playlist.mediaItems.isEmpty) return;

    _isPreloading = true;

    try {
      // Get next media index
      final nextIndex = (_currentIndex + 1) % widget.playlist.mediaItems.length;
      final nextMedia = widget.playlist.mediaItems[nextIndex];

      debugPrint('🔄 Preloading next media: ${nextMedia.mediaName} (${nextMedia.mediaType})');

      // Check if next media is downloaded
      if (!nextMedia.downloaded || nextMedia.localPath == null) {
        debugPrint('❌ Next media not downloaded, skipping preload');
        _isPreloading = false;
        return;
      }

      final nextMediaFile = File(nextMedia.localPath!);
      if (!await nextMediaFile.exists()) {
        debugPrint('❌ Next media file not found, skipping preload');
        _isPreloading = false;
        return;
      }

      // Dispose old preloaded controller
      _nextVideoPlayerController?.dispose();
      _nextVideoPlayerController = null;

      if (nextMedia.mediaType == 'video') {
        // Preload video
        debugPrint('📹 Preloading video: ${nextMedia.mediaName}');
        _nextVideoPlayerController = VideoPlayerController.file(nextMediaFile);
        await _nextVideoPlayerController!.initialize();
        _nextIsImage = false;
        debugPrint('✅ Video preloaded successfully');
      } else if (nextMedia.mediaType == 'image') {
        // Preload image (by caching it)
        debugPrint('🖼️ Preloading image: ${nextMedia.mediaName}');
        // Images are preloaded by the Image widget automatically
        _nextIsImage = true;
        // Pre-cache the image
        if (mounted) {
          await precacheImage(FileImage(nextMediaFile), context);
          debugPrint('✅ Image preloaded successfully');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error preloading next media: $e');
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> _initializeImage(dynamic currentMedia, File file) async {
    // CRITICAL: Validate file exists before attempting to display
    if (!await file.exists()) {
      debugPrint('❌ [IMAGE] File does not exist: ${file.path}');
      setState(() {
        _errorMessage = 'Image file not found. Re-downloading...';
      });
      // Trigger automatic re-download
      if (mounted) {
        context.read<VideoBloc>().add(RedownloadMediaItem(mediaIndex: _currentIndex));
      }
      return;
    }

    // Validate file size (empty files are invalid)
    final fileSize = await file.length();
    if (fileSize == 0) {
      debugPrint('❌ [IMAGE] File is empty: ${file.path}');
      setState(() {
        _errorMessage = 'Image file is corrupted. Re-downloading...';
      });
      if (mounted) {
        context.read<VideoBloc>().add(RedownloadMediaItem(mediaIndex: _currentIndex));
      }
      return;
    }

    debugPrint('✅ [IMAGE] File validated - Size: $fileSize bytes');

    // Get duration from timing (in seconds)
    final durationSeconds = currentMedia.timing.duration;

    setState(() {
      _isImage = true;
      _isPlaying = true;
      _imageProgress = 0.0;
      _imageRemainingSeconds = durationSeconds;
    });

    debugPrint('🖼️ Displaying image for $durationSeconds seconds: ${currentMedia.mediaName}');

    // Start timer for image duration
    _imageDisplayTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted) {
        _handleMediaCompletion();
      }
    });

    // Start progress timer (update every 100ms for smooth progress bar)
    final startTime = DateTime.now();
    _imageProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = elapsed / (durationSeconds * 1000);

      // Update remaining seconds
      final remaining = durationSeconds - (elapsed / 1000).ceil();

      setState(() {
        _imageProgress = progress.clamp(0.0, 1.0);
        _imageRemainingSeconds = remaining.clamp(0, durationSeconds);
      });

      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }

  Future<void> _initializeVideo(dynamic currentMedia, File file) async {
    setState(() {
      _isImage = false;
      _isPlaying = true;
    });

    // FAST SWITCH: Check if this is the first media and we have a pre-initialized controller
    if (_currentIndex == 0 && _controllerManager.hasController(widget.playlist.id)) {
      debugPrint('⚡ [FAST_SWITCH] Using pre-initialized controller for playlist ${widget.playlist.id}');
      _videoPlayerController = _controllerManager.takeController(widget.playlist.id);
      _usedPreInitializedController = true;

      // Seek to beginning and play
      await _videoPlayerController!.seekTo(Duration.zero);
    }
    // SMART WAIT: Check if controller is being initialized, wait for it briefly
    else if (_currentIndex == 0 && _controllerManager.isInitializing(widget.playlist.id)) {
      debugPrint('⏳ [FAST_SWITCH] Controller initializing for playlist ${widget.playlist.id}, waiting...');

      // Wait for up to 5 seconds for pre-initialization to complete
      final success = await _controllerManager.waitForPlaylistReady(
        widget.playlist.id,
        timeout: const Duration(seconds: 5),
      );

      if (success && _controllerManager.hasController(widget.playlist.id)) {
        debugPrint('✅ [FAST_SWITCH] Pre-initialization completed! Using controller');
        _videoPlayerController = _controllerManager.takeController(widget.playlist.id);
        _usedPreInitializedController = true;
        await _videoPlayerController!.seekTo(Duration.zero);
      } else {
        // Timeout or failed, initialize normally
        debugPrint('⏳ [FAST_SWITCH] Pre-initialization timeout, initializing normally');
        _videoPlayerController = VideoPlayerController.file(file);
        await _videoPlayerController!.initialize();
      }
    }
    // Check if we have a preloaded video controller (for next media)
    else if (_nextVideoPlayerController != null && !_nextIsImage) {
      debugPrint('✨ Using preloaded next video controller');
      _videoPlayerController = _nextVideoPlayerController;
      _nextVideoPlayerController = null;
    } else {
      // Initialize new video controller (fallback)
      debugPrint('⏳ Initializing new video controller');
      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();
    }

    // Initialize Chewie controller
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: currentMedia.timing.loop && currentMedia.nTimePlay > 1,
      showControls: false,
      allowFullScreen: false,
      allowMuting: false,
      allowPlaybackSpeedChanging: false,
      aspectRatio: widget.playlist.width / widget.playlist.height,
    );

    // Listen for video completion
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.position == _videoPlayerController!.value.duration) {
        _handleMediaCompletion();
      }
    });

    debugPrint('🎬 Video initialized and playing');
  }

  void _disposeCurrentMedia() {
    _imageDisplayTimer?.cancel();
    _imageDisplayTimer = null;
    _imageProgressTimer?.cancel();
    _imageProgressTimer = null;
    _chewieController?.dispose();
    _chewieController = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  void _handleMediaCompletion() {
    final currentMedia = widget.playlist.mediaItems[_currentIndex];
    _playCount++;

    // Check if we need to repeat this media
    if (_playCount < currentMedia.nTimePlay) {
      _initializePlayer();
    } else {
      _playCount = 0;
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    final nextIndex = (_currentIndex + 1) % widget.playlist.mediaItems.length;

    // Check if we completed the entire playlist
    if (nextIndex == 0) {
      // Check playlist repeat settings
      if (widget.playlist.playbackConfig.repeat) {
        context.read<VideoBloc>().add(PlayVideo(index: nextIndex));
      } else {
        // Playlist completed, stop playback
        context.read<VideoBloc>().add(const PauseVideo());
      }
    } else {
      context.read<VideoBloc>().add(PlayVideo(index: nextIndex));
    }
  }

  void _playNextDownloadedVideo() {
    // Find next downloaded media
    int nextIndex = (_currentIndex + 1) % widget.playlist.mediaItems.length;
    int attempts = 0;
    final maxAttempts = widget.playlist.mediaItems.length;

    while (attempts < maxAttempts) {
      final nextMedia = widget.playlist.mediaItems[nextIndex];
      if (nextMedia.downloaded && nextMedia.localPath != null) {
        // Found a downloaded media, play it
        debugPrint('✅ Found downloaded media at index $nextIndex: ${nextMedia.mediaName}');
        context.read<VideoBloc>().add(PlayVideo(index: nextIndex));
        return;
      }

      nextIndex = (nextIndex + 1) % widget.playlist.mediaItems.length;
      attempts++;
    }

    // No downloaded media found, show error
    debugPrint('❌ No downloaded media available in playlist');
    setState(() {
      _errorMessage = 'No downloaded media available. Downloading in progress...';
    });
  }

  void _captureScreenshot() {
    final currentMedia = widget.playlist.mediaItems[_currentIndex];
    debugPrint('Capturing screenshot for media: ${currentMedia.mediaId}');
    // TODO: Implement actual screenshot capture using screenshot package
    // context.read<VideoBloc>().add(CaptureAndUploadScreenshot(...));
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _imageDisplayTimer?.cancel();
    _imageProgressTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _nextVideoPlayerController?.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isFullscreen) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VideoBloc, VideoState>(
      listener: (context, state) {
        debugPrint('🎧 BlocListener received state: ${state.runtimeType}');

        if (state is MediaItemRedownloading && state.mediaIndex == _currentIndex) {
          // Update error message to show download progress
          setState(() {
            _errorMessage = 'Re-downloading video... ${(state.progress * 100).toStringAsFixed(0)}%';
          });
        } else if (state is VideoLoaded) {
          debugPrint('🎧 VideoLoaded state received in BlocListener');
          debugPrint('   - isPlaying: ${state.isPlaying}');
          debugPrint('   - currentMediaIndex: ${state.currentMediaIndex}');
          debugPrint('   - Local _isPlaying: $_isPlaying');
          debugPrint('   - Local _currentIndex: $_currentIndex');

          // Handle re-download completion
          if (_errorMessage != null && _errorMessage!.contains('Re-downloading')) {
            debugPrint('🔄 Clearing re-download error and reinitializing');
            setState(() {
              _errorMessage = null;
            });
            _initializePlayer();
            return;
          }

          // Handle play/pause state changes from WebSocket or other sources
          debugPrint('🎮 Processing state changes...');

          // If media index changed, reinitialize player
          if (state.currentMediaIndex != _currentIndex) {
            debugPrint('🔄 Media index changed from $_currentIndex to ${state.currentMediaIndex}');
            _currentIndex = state.currentMediaIndex;
            _playCount = 0;
            _initializePlayer();
            return;
          }

          // Handle play/pause state
          if (state.isPlaying != _isPlaying) {
            debugPrint('🎮 Play state changed - isPlaying: ${state.isPlaying}');
            setState(() {
              _isPlaying = state.isPlaying;
            });

            if (_isImage) {
              // Handle image play/pause
              if (state.isPlaying) {
                // Resume image timer
                if (_imageRemainingSeconds > 0) {
                  _imageDisplayTimer = Timer(Duration(seconds: _imageRemainingSeconds), () {
                    if (mounted) {
                      _handleMediaCompletion();
                    }
                  });

                  // Resume progress timer
                  final startProgress = _imageProgress;
                  final startTime = DateTime.now();
                  _imageProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                    if (!mounted || !_isPlaying) {
                      timer.cancel();
                      return;
                    }

                    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
                    final progressIncrement = elapsed / (_imageRemainingSeconds * 1000);
                    final progress = startProgress + progressIncrement;

                    setState(() {
                      _imageProgress = progress.clamp(0.0, 1.0);
                    });

                    if (progress >= 1.0) {
                      timer.cancel();
                    }
                  });
                }
              } else {
                // Pause image
                _imageDisplayTimer?.cancel();
                _imageProgressTimer?.cancel();
              }
            } else {
              // Handle video play/pause
              if (state.isPlaying) {
                _videoPlayerController?.play();
                debugPrint('▶️ Video playing');
              } else {
                _videoPlayerController?.pause();
                debugPrint('⏸️ Video paused');
              }
            }
          }
        }
      },
      child: _buildPlayerContent(),
    );
  }

  Widget _buildPlayerContent() {
    if (widget.playlist.mediaItems.isEmpty) {
      return const Center(
        child: Text('No media items in playlist', style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    // Show error message if there's an error
    if (_errorMessage != null) {
      final isRedownloading = _errorMessage!.contains('Re-downloading');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRedownloading)
              const CircularProgressIndicator(color: Colors.cyanAccent)
            else
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            if (!isRedownloading) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _playNextVideo,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700),
                child: const Text('Skip to Next', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      );
    }

    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Display IMAGE or VIDEO (no loading indicator, just black screen during transition)
              if (_isImage)
                _buildImageDisplay()
              else if (_chewieController != null &&
                  _videoPlayerController != null &&
                  _videoPlayerController!.value.isInitialized)
                Center(child: Chewie(controller: _chewieController!))
              else
                // Show black screen instead of loading indicator during transition
                Container(width: double.infinity, height: double.infinity, color: Colors.black),
              // Text overlay
              if (widget.textOverlayConfig != null) TextOverlayWidget(config: widget.textOverlayConfig!),
              // Controls
              if (_showControls && !_isFullscreen) _buildControlsOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageDisplay() {
    final currentMedia = widget.playlist.mediaItems[_currentIndex];

    // CRITICAL: Additional safety check - validate localPath exists
    if (currentMedia.localPath == null || currentMedia.localPath!.isEmpty) {
      debugPrint('❌ [IMAGE_DISPLAY] No local path for image: ${currentMedia.mediaName}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Image path missing:\n${currentMedia.mediaName}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final imageFile = File(currentMedia.localPath!);

    return Center(
      child: Stack(
        children: [
          // Image display with unique key to force reload on playlist change
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Image.file(
              imageFile,
              // Use unique key with timestamp to force fresh load on each initialization
              key: ValueKey('${widget.playlist.id}_${currentMedia.mediaId}_${DateTime.now().millisecondsSinceEpoch}'),
              fit: BoxFit.contain,
              // Force fresh load from file system (no memory cache)
              cacheWidth: null,
              cacheHeight: null,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ [IMAGE_ERROR] Error loading image: $error');
                debugPrint('   Media: ${currentMedia.mediaName}');
                debugPrint('   Type: ${currentMedia.mediaType}');
                debugPrint('   Path: ${currentMedia.localPath}');
                debugPrint('   File exists sync: ${imageFile.existsSync()}');

                // CRITICAL: Check if file is actually an image before re-downloading
                final fileName = currentMedia.localPath?.split('/').last ?? '';
                final isActuallyVideo = fileName.toLowerCase().endsWith('.mp4') ||
                    fileName.toLowerCase().endsWith('.avi') ||
                    fileName.toLowerCase().endsWith('.mov') ||
                    fileName.toLowerCase().endsWith('.webm');

                if (isActuallyVideo) {
                  // This is a VIDEO file being loaded as IMAGE - data corruption!
                  debugPrint('⚠️ [IMAGE_ERROR] CRITICAL: Video file detected in image display!');
                  debugPrint('   This indicates data corruption. Skipping to next media.');

                  // Skip to next media instead of re-downloading
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _playNextVideo();
                    }
                  });

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 80, color: Colors.red),
                        const SizedBox(height: 20),
                        Text(
                          'Data corruption detected:\nVideo file in image slot\nSkipping to next media...',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Only trigger re-download for actual image files
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _errorMessage == null) {
                    debugPrint('🔄 [IMAGE_ERROR] Auto-triggering re-download for missing/corrupt image');
                    context.read<VideoBloc>().add(RedownloadMediaItem(mediaIndex: _currentIndex));
                  }
                });

                // Show loading state while re-download is triggered
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.cyanAccent),
                      const SizedBox(height: 20),
                      Text(
                        'Re-downloading image:\n${currentMedia.mediaName}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Progress indicator at the bottom (hide in fullscreen)
          if (!_isFullscreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 4,
                color: Colors.white.withValues(alpha: 0.3),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _imageProgress,
                  child: Container(color: Colors.cyanAccent),
                ),
              ),
            ),
          // Duration indicator (top right corner, hide in fullscreen)
          if (!_isFullscreen)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${currentMedia.timing.duration}s',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    // For images, use _isPlaying state. For videos, use video controller state
    final isPlaying = _isImage ? _isPlaying : (_videoPlayerController?.value.isPlaying ?? false);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Playlist name
                Expanded(
                  child: Text(
                    widget.playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(2.0, 2.0))],
                    ),
                  ),
                ),
                // Media index indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.playlist.mediaItems.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Center play/pause button
          Center(
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.5)),
              child: IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 48),
                onPressed: () {
                  // Let VideoBloc handle state change, BlocListener will update UI
                  if (isPlaying) {
                    debugPrint('🎮 User pressed PAUSE button');
                    context.read<VideoBloc>().add(const PauseVideo());
                  } else {
                    debugPrint('🎮 User pressed PLAY button');
                    context.read<VideoBloc>().add(PlayVideo(index: _currentIndex));
                  }
                  _startHideControlsTimer();
                },
              ),
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous button
                _buildControlButton(
                  icon: Icons.skip_previous,
                  onPressed: () {
                    context.read<VideoBloc>().add(const PlayPreviousVideo());
                  },
                  label: 'Previous',
                ),
                // Replay button
                _buildControlButton(
                  icon: Icons.replay,
                  onPressed: () {
                    debugPrint('🔄 User pressed REPLAY button');
                    if (_isImage) {
                      // Restart image display timer
                      _playCount = 0;
                      _initializePlayer();
                    } else {
                      // Restart video
                      _videoPlayerController?.seekTo(Duration.zero);
                      _videoPlayerController?.play();
                    }
                    // Ensure playing state
                    context.read<VideoBloc>().add(PlayVideo(index: _currentIndex));
                  },
                  label: 'Replay',
                ),
                // Next button
                _buildControlButton(
                  icon: Icons.skip_next,
                  onPressed: () {
                    context.read<VideoBloc>().add(const PlayNextVideo());
                  },
                  label: 'Next',
                ),
                // Fullscreen toggle button
                _buildControlButton(
                  icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  onPressed: () {
                    setState(() {
                      _isFullscreen = !_isFullscreen;
                      _showControls = !_isFullscreen;
                    });
                  },
                  label: _isFullscreen ? 'Exit' : 'Fullscreen',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.6)),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: () {
              onPressed();
              _startHideControlsTimer();
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            shadows: const [Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(1.0, 1.0))],
          ),
        ),
      ],
    );
  }
}
