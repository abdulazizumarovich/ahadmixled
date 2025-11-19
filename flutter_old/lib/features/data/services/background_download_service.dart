import 'dart:async';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/usecases/video/download_playlist_usecase.dart';

/// Background download service for playlists
/// Downloads playlists in the background without blocking UI
class BackgroundDownloadService {
  final DownloadPlaylistUseCase downloadPlaylistUseCase;

  final List<PlaylistEntity> _downloadQueue = [];
  bool _isDownloading = false;
  StreamController<DownloadProgress>? _progressController;

  BackgroundDownloadService({required this.downloadPlaylistUseCase});

  /// Add playlist to download queue
  void enqueueDownload(PlaylistEntity playlist) {
    // Don't add if already in queue
    if (_downloadQueue.any((p) => p.id == playlist.id)) {
      AppLogger.videoInfo('⏭️ Playlist already in download queue: ${playlist.name}');
      return;
    }

    // Check if playlist is already fully downloaded
    if (playlist.status.isReady && playlist.status.allDownloaded) {
      // Check if all media items are actually downloaded
      final allMediaDownloaded = playlist.mediaItems.every((item) => item.downloaded == true);

      if (allMediaDownloaded) {
        AppLogger.videoInfo('✅ Playlist already fully downloaded, skipping: ${playlist.name}');
        return;
      }
    }

    // Add to queue for download/verification
    _downloadQueue.add(playlist);
    AppLogger.videoInfo('📥 Added to download queue: ${playlist.name} (Queue: ${_downloadQueue.length})');

    // Start processing queue if not already downloading
    if (!_isDownloading) {
      _processQueue();
    }
  }

  /// Add multiple playlists to download queue
  void enqueueMultiple(List<PlaylistEntity> playlists) {
    for (final playlist in playlists) {
      enqueueDownload(playlist);
    }
  }

  /// Process download queue
  Future<void> _processQueue() async {
    if (_isDownloading || _downloadQueue.isEmpty) {
      return;
    }

    _isDownloading = true;

    while (_downloadQueue.isNotEmpty) {
      final playlist = _downloadQueue.removeAt(0);

      try {
        AppLogger.videoInfo('⬇️ Starting background download: ${playlist.name}');

        _emitProgress(DownloadProgress(playlist: playlist, status: DownloadStatus.downloading, progress: 0.0));

        final result = await downloadPlaylistUseCase(
          DownloadPlaylistParams(
            playlist: playlist,
            onProgress: (downloaded, total) {
              final progress = total > 0 ? downloaded / total : 0.0;
              _emitProgress(
                DownloadProgress(
                  playlist: playlist,
                  status: DownloadStatus.downloading,
                  progress: progress,
                  downloadedItems: downloaded,
                  totalItems: total,
                ),
              );
            },
          ),
        );

        result.fold(
          (failure) {
            AppLogger.videoError('❌ Failed to download playlist: ${playlist.name}', failure.message);
            _emitProgress(
              DownloadProgress(
                playlist: playlist,
                status: DownloadStatus.failed,
                progress: 0.0,
                error: failure.message,
              ),
            );
          },
          (downloadedPlaylist) {
            AppLogger.videoInfo('✅ Successfully downloaded playlist: ${playlist.name}');
            _emitProgress(
              DownloadProgress(playlist: downloadedPlaylist, status: DownloadStatus.completed, progress: 1.0),
            );
          },
        );

        // Small delay between downloads to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        AppLogger.videoError('❌ Error downloading playlist: ${playlist.name}', e);
        _emitProgress(
          DownloadProgress(playlist: playlist, status: DownloadStatus.failed, progress: 0.0, error: e.toString()),
        );
      }
    }

    _isDownloading = false;
    AppLogger.videoInfo('✅ Download queue completed');
  }

  /// Emit progress update
  void _emitProgress(DownloadProgress progress) {
    _progressController?.add(progress);
  }

  /// Listen to download progress updates
  Stream<DownloadProgress> get progressStream {
    _progressController ??= StreamController<DownloadProgress>.broadcast();
    return _progressController!.stream;
  }

  /// Get current queue size
  int get queueSize => _downloadQueue.length;

  /// Check if currently downloading
  bool get isDownloading => _isDownloading;

  /// Check if there are any downloads (active or queued)
  bool get hasDownloads => _isDownloading || _downloadQueue.isNotEmpty;

  /// Clear download queue
  void clearQueue() {
    _downloadQueue.clear();
    AppLogger.videoInfo('🗑️ Download queue cleared');
  }

  /// Cancel current download (not fully implemented - would need cancellation token)
  void cancelCurrentDownload() {
    // TODO: Implement cancellation mechanism
    AppLogger.videoInfo('⏹️ Download cancellation requested');
  }

  /// Dispose resources
  void dispose() {
    _progressController?.close();
    _progressController = null;
    _downloadQueue.clear();
  }
}

/// Download progress data
class DownloadProgress {
  final PlaylistEntity playlist;
  final DownloadStatus status;
  final double progress;
  final int? downloadedItems;
  final int? totalItems;
  final String? error;

  const DownloadProgress({
    required this.playlist,
    required this.status,
    required this.progress,
    this.downloadedItems,
    this.totalItems,
    this.error,
  });
}

/// Download status enum
enum DownloadStatus { queued, downloading, completed, failed }
