import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tv_monitor/core/constants/api_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/datasources/remote/video_remote_datasource.dart';
import 'package:tv_monitor/features/data/datasources/local/video_local_datasource.dart';
import 'package:tv_monitor/features/data/models/playlist_model.dart';
import 'package:tv_monitor/features/data/models/media_item_model.dart';
import 'package:tv_monitor/features/data/models/playlist_status_model.dart';

enum PlaylistDownloadStatus { idle, downloading, completed, failed }

class PlaylistDownloadProgress {
  final int playlistId;
  final PlaylistDownloadStatus status;
  final int totalItems;
  final int downloadedItems;
  final String? currentMediaName;
  final double? currentProgress;
  final String? error;

  const PlaylistDownloadProgress({
    required this.playlistId,
    required this.status,
    required this.totalItems,
    required this.downloadedItems,
    this.currentMediaName,
    this.currentProgress,
    this.error,
  });

  double get overallProgress {
    if (totalItems == 0) return 0;
    return downloadedItems / totalItems;
  }
}

class PlaylistDownloadManager {
  final VideoRemoteDataSource remoteDataSource;
  final VideoLocalDataSource localDataSource;
  final Function(PlaylistDownloadProgress)? onProgressUpdate;

  PlaylistDownloadManager({required this.remoteDataSource, required this.localDataSource, this.onProgressUpdate});

  Future<PlaylistModel> downloadPlaylist(PlaylistModel playlist) async {
    AppLogger.videoInfo('🔍 Checking playlist for download: ${playlist.name}');

    // First, verify all existing downloads
    int alreadyDownloadedCount = 0;
    for (final mediaItem in playlist.mediaItems) {
      if (mediaItem.downloaded == true && mediaItem.localPath != null) {
        final file = File(mediaItem.localPath!);
        if (await file.exists()) {
          alreadyDownloadedCount++;
        }
      }
    }

    // If all items are already downloaded, skip download
    if (alreadyDownloadedCount == playlist.mediaItems.length) {
      AppLogger.videoInfo('✅ All media items already downloaded for playlist: ${playlist.name}');

      // Return existing playlist with updated status
      final updatedPlaylist = PlaylistModel(
        id: playlist.id,
        name: playlist.name,
        width: playlist.width,
        height: playlist.height,
        duration: playlist.duration,
        mediaItems: playlist.mediaItems,
        playbackConfig: playlist.playbackConfig,
        status: PlaylistStatusModel(isReady: true, allDownloaded: true, missingFiles: [], lastVerified: DateTime.now()),
      );

      await localDataSource.updatePlaylist(updatedPlaylist);

      onProgressUpdate?.call(
        PlaylistDownloadProgress(
          playlistId: playlist.id,
          status: PlaylistDownloadStatus.completed,
          totalItems: playlist.mediaItems.length,
          downloadedItems: playlist.mediaItems.length,
        ),
      );

      return updatedPlaylist;
    }

    AppLogger.videoInfo(
      '📥 Starting download for playlist: ${playlist.name} ($alreadyDownloadedCount/${playlist.mediaItems.length} already downloaded)',
    );

    onProgressUpdate?.call(
      PlaylistDownloadProgress(
        playlistId: playlist.id,
        status: PlaylistDownloadStatus.downloading,
        totalItems: playlist.mediaItems.length,
        downloadedItems: 0,
      ),
    );

    List<MediaItemModel> updatedMediaItems = [];
    List<String> missingFiles = [];
    int downloadedCount = 0;

    for (final mediaItem in playlist.mediaItems) {
      try {
        // Check if this specific media item is already downloaded
        if (mediaItem.downloaded == true && mediaItem.localPath != null) {
          final file = File(mediaItem.localPath!);
          if (await file.exists()) {
            AppLogger.videoInfo('✅ Media already exists, skipping: ${mediaItem.mediaName}');
            updatedMediaItems.add(mediaItem);
            downloadedCount++;
            continue;
          }
        }

        AppLogger.videoInfo('⬇️ Downloading media: ${mediaItem.mediaName}');

        onProgressUpdate?.call(
          PlaylistDownloadProgress(
            playlistId: playlist.id,
            status: PlaylistDownloadStatus.downloading,
            totalItems: playlist.mediaItems.length,
            downloadedItems: downloadedCount,
            currentMediaName: mediaItem.mediaName,
            currentProgress: 0,
          ),
        );

        final localPath = await _downloadMediaItem(mediaItem, (received, total) {
          onProgressUpdate?.call(
            PlaylistDownloadProgress(
              playlistId: playlist.id,
              status: PlaylistDownloadStatus.downloading,
              totalItems: playlist.mediaItems.length,
              downloadedItems: downloadedCount,
              currentMediaName: mediaItem.mediaName,
              currentProgress: received / total,
            ),
          );
        });

        final updatedItem = MediaItemModel(
          mediaId: mediaItem.mediaId,
          order: mediaItem.order,
          mediaName: mediaItem.mediaName,
          mediaType: mediaItem.mediaType,
          mimetype: mediaItem.mimetype,
          mediaUrl: mediaItem.mediaUrl,
          localPath: localPath,
          fileSize: mediaItem.fileSize,
          downloaded: true,
          downloadDate: DateTime.now(),
          checksum: mediaItem.checksum,
          layout: mediaItem.layout,
          timing: mediaItem.timing,
          effects: mediaItem.effects,
          nTimePlay: mediaItem.nTimePlay,
        );

        updatedMediaItems.add(updatedItem);
        downloadedCount++;

        AppLogger.videoInfo('✅ Downloaded ${mediaItem.mediaName} successfully');
      } catch (e) {
        AppLogger.videoError('❌ Failed to download ${mediaItem.mediaName}', e);
        missingFiles.add(mediaItem.mediaName);
        updatedMediaItems.add(mediaItem);
      }
    }

    final allDownloaded = missingFiles.isEmpty;
    final updatedStatus = PlaylistStatusModel(
      isReady: allDownloaded,
      allDownloaded: allDownloaded,
      missingFiles: missingFiles,
      lastVerified: DateTime.now(),
    );

    final updatedPlaylist = PlaylistModel(
      id: playlist.id,
      name: playlist.name,
      width: playlist.width,
      height: playlist.height,
      duration: playlist.duration,
      mediaItems: updatedMediaItems,
      playbackConfig: playlist.playbackConfig,
      status: updatedStatus,
    );

    await localDataSource.updatePlaylist(updatedPlaylist);

    onProgressUpdate?.call(
      PlaylistDownloadProgress(
        playlistId: playlist.id,
        status: allDownloaded ? PlaylistDownloadStatus.completed : PlaylistDownloadStatus.failed,
        totalItems: playlist.mediaItems.length,
        downloadedItems: downloadedCount,
        error: allDownloaded ? null : 'Some files failed to download',
      ),
    );

    AppLogger.videoInfo('Playlist download completed. Downloaded: $downloadedCount/${playlist.mediaItems.length}');

    return updatedPlaylist;
  }

  Future<String> _downloadMediaItem(MediaItemModel mediaItem, Function(int, int)? onProgress) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${directory.path}/vnnox_media');

    AppLogger.videoInfo('Media directory path: ${mediaDir.path}');

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
      AppLogger.videoInfo('Created media directory');
    }

    final fileName = '${mediaItem.mediaId}_${mediaItem.mediaName}';
    final savePath = '${mediaDir.path}/$fileName';

    AppLogger.videoInfo('Attempting to save to: $savePath');

    final file = File(savePath);
    if (await file.exists()) {
      AppLogger.videoInfo('🔍 File exists, verifying: $fileName');

      // Smart caching: verify file integrity with checksum if available
      final checksum = mediaItem.checksum;
      if (checksum.isNotEmpty) {
        final fileChecksum = await _calculateChecksum(file);
        if (fileChecksum == checksum) {
          AppLogger.videoInfo('✅ File valid (checksum match), using cached: $fileName');
          return savePath;
        } else {
          AppLogger.videoInfo('⚠️ Checksum mismatch, re-downloading: $fileName');
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            AppLogger.videoInfo('⚠️ Could not delete file (might be already deleted): $e');
          }
        }
      } else {
        // No checksum available, verify file size instead
        try {
          final fileSize = await file.length();
          final expectedSize = mediaItem.fileSize;
          if (fileSize == expectedSize) {
            AppLogger.videoInfo('✅ File valid (size match), using cached: $fileName');
            return savePath;
          } else if (fileSize > 1000) {
            // File has reasonable size, assume it's OK
            AppLogger.videoInfo('✅ File exists with reasonable size, using cached: $fileName');
            return savePath;
          } else {
            AppLogger.videoInfo('⚠️ Size mismatch (expected: $expectedSize, got: $fileSize), re-downloading: $fileName');
            try {
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              AppLogger.videoInfo('⚠️ Could not delete file (might be already deleted): $e');
            }
          }
        } catch (e) {
          // File exists but can't get length (permissions issue, corruption, etc.)
          AppLogger.videoInfo('⚠️ File exists but cannot get length: $e - re-downloading: $fileName');
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (deleteError) {
            AppLogger.videoInfo('⚠️ Could not delete corrupted file: $deleteError');
          }
        }
      }
    }

    final fullUrl = mediaItem.mediaUrl.startsWith('http')
        ? mediaItem.mediaUrl
        : '${ApiConstants.domain}${mediaItem.mediaUrl}';

    AppLogger.videoInfo('Downloading from URL: $fullUrl');

    try {
      await remoteDataSource.downloadMedia(url: fullUrl, savePath: savePath, onProgress: onProgress);

      // Verify file exists after download
      if (await file.exists()) {
        try {
          final fileSize = await file.length();
          AppLogger.videoInfo('Download completed. File size: $fileSize bytes at $savePath');
        } catch (e) {
          AppLogger.videoError('Download completed but cannot verify file size: $e', null);
          // File exists but has issues - let it fail at playback time
        }
      } else {
        AppLogger.videoError('Download completed but file not found at $savePath', null);
        throw VideoDownloadException(message: 'File not found after download');
      }
    } catch (e) {
      AppLogger.videoError('Failed to download media', e);
      rethrow;
    }

    return savePath;
  }

  Future<void> deletePlaylistMedia(PlaylistModel playlist) async {
    for (final mediaItem in playlist.mediaItems) {
      if (mediaItem.localPath != null) {
        try {
          final file = File(mediaItem.localPath!);
          if (await file.exists()) {
            await file.delete();
            AppLogger.videoInfo('Deleted media file: ${mediaItem.mediaName}');
          }
        } catch (e) {
          AppLogger.videoError('Failed to delete media file: ${mediaItem.mediaName}', e);
        }
      }
    }
  }

  Future<PlaylistModel> redownloadMediaItem({
    required PlaylistModel playlist,
    required int mediaIndex,
    Function(double)? onProgress,
  }) async {
    if (mediaIndex < 0 || mediaIndex >= playlist.mediaItems.length) {
      throw Exception('Invalid media index: $mediaIndex');
    }

    final mediaItem = playlist.mediaItems[mediaIndex];
    AppLogger.videoInfo('Re-downloading media: ${mediaItem.mediaName}');

    try {
      final localPath = await _downloadMediaItem(mediaItem, (received, total) {
        onProgress?.call(received / total);
      });

      final updatedItem = MediaItemModel(
        mediaId: mediaItem.mediaId,
        order: mediaItem.order,
        mediaName: mediaItem.mediaName,
        mediaType: mediaItem.mediaType,
        mimetype: mediaItem.mimetype,
        mediaUrl: mediaItem.mediaUrl,
        localPath: localPath,
        fileSize: mediaItem.fileSize,
        downloaded: true,
        downloadDate: DateTime.now(),
        checksum: mediaItem.checksum,
        layout: mediaItem.layout,
        timing: mediaItem.timing,
        effects: mediaItem.effects,
        nTimePlay: mediaItem.nTimePlay,
      );

      final updatedMediaItems = List<MediaItemModel>.from(playlist.mediaItems);
      updatedMediaItems[mediaIndex] = updatedItem;

      final updatedPlaylist = PlaylistModel(
        id: playlist.id,
        name: playlist.name,
        width: playlist.width,
        height: playlist.height,
        duration: playlist.duration,
        mediaItems: updatedMediaItems,
        playbackConfig: playlist.playbackConfig,
        status: playlist.status,
      );

      await localDataSource.updatePlaylist(updatedPlaylist);

      AppLogger.videoInfo('Media re-downloaded successfully: ${mediaItem.mediaName}');
      return updatedPlaylist;
    } catch (e) {
      AppLogger.videoError('Failed to re-download media: ${mediaItem.mediaName}', e);
      rethrow;
    }
  }

  /// Calculate MD5 checksum of a file for integrity verification
  Future<String> _calculateChecksum(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      AppLogger.videoError('Failed to calculate checksum', e);
      return '';
    }
  }
}
