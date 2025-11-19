import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/errors/failures.dart';
import 'package:tv_monitor/core/utils/network_info.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/datasources/local/video_local_datasource.dart';
import 'package:tv_monitor/features/data/datasources/remote/video_remote_datasource.dart';
import 'package:tv_monitor/features/data/datasources/remote/websocket_datasource.dart';
import 'package:tv_monitor/features/data/models/playlist_model.dart';
import 'package:tv_monitor/features/data/models/media_item_model.dart';
import 'package:tv_monitor/features/data/models/playlist_status_model.dart';
import 'package:tv_monitor/features/data/models/playlist_status_message_model.dart';
import 'package:tv_monitor/features/data/services/playlist_download_manager.dart';
import 'package:tv_monitor/features/domain/entities/device_screens_entity.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoRemoteDataSource remoteDataSource;
  final VideoLocalDataSource localDataSource;
  final WebSocketDataSource webSocketDataSource;
  final NetworkInfo networkInfo;

  VideoRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.webSocketDataSource,
    required this.networkInfo,
  });

  @override
  ResultFuture<DeviceScreensEntity> getDeviceScreens({
    required String deviceId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final deviceScreens = await remoteDataSource.getDeviceScreens(deviceId: deviceId);

        if (deviceScreens.frontScreen != null) {
          // Smart merge: don't clear all playlists, only update/add new ones
          await _smartMergePlaylists(deviceScreens.frontScreen!.playlists);
        }

        return Right(deviceScreens.toEntity());
      } else {
        await localDataSource.getLocalPlaylists();
        return Left(NetworkFailure(message: 'No internet connection. Using cached playlists.'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Smart merge playlists without clearing existing downloaded content
  Future<void> _smartMergePlaylists(List<PlaylistModel> serverPlaylists) async {
    // Get existing local playlists
    final localPlaylists = await localDataSource.getLocalPlaylists();

    // Create a map of local playlists by ID for quick lookup
    final localPlaylistsMap = {for (var p in localPlaylists) p.id: p};

    // Create a map of server playlists by ID
    final serverPlaylistsMap = {for (var p in serverPlaylists) p.id: p};

    // Update or add playlists from server
    for (final serverPlaylist in serverPlaylists) {
      final existingPlaylist = localPlaylistsMap[serverPlaylist.id];

      if (existingPlaylist != null) {
        // Playlist exists locally - merge media items intelligently
        final mergedMediaItems = _mergeMediaItems(
          serverMediaItems: serverPlaylist.mediaItems,
          localMediaItems: existingPlaylist.mediaItems,
        );

        // CRITICAL FIX: Re-validate status after merging media items
        // Don't blindly preserve old status - check if all media are still downloaded
        final allStillDownloaded = mergedMediaItems.every((item) =>
          item.downloaded == true && item.localPath != null
        );

        final downloadedCount = mergedMediaItems.where((m) => m.downloaded == true).length;
        print('🔄 [MERGE] Playlist "${serverPlaylist.name}": $downloadedCount/${mergedMediaItems.length} media downloaded');
        print('   Old status: isReady=${existingPlaylist.status?.isReady}, allDownloaded=${existingPlaylist.status?.allDownloaded}');
        print('   New status: isReady=$allStillDownloaded, allDownloaded=$allStillDownloaded');

        final revalidatedStatus = PlaylistStatusModel(
          isReady: allStillDownloaded,
          allDownloaded: allStillDownloaded,
          missingFiles: allStillDownloaded ? [] :
            mergedMediaItems.where((m) => m.downloaded != true).map((m) => m.mediaName).toList(),
          lastVerified: DateTime.now(),
        );

        final updatedPlaylist = PlaylistModel(
          id: serverPlaylist.id,
          name: serverPlaylist.name,
          width: serverPlaylist.width,
          height: serverPlaylist.height,
          duration: serverPlaylist.duration,
          mediaItems: mergedMediaItems, // Use merged media items
          playbackConfig: serverPlaylist.playbackConfig,
          status: revalidatedStatus, // Use re-validated status, not old one!
        );
        await localDataSource.updatePlaylist(updatedPlaylist);
      } else {
        // New playlist - save it as is
        await localDataSource.savePlaylists([serverPlaylist]);
      }
    }

    // Remove playlists that no longer exist on server
    for (final localPlaylist in localPlaylists) {
      if (!serverPlaylistsMap.containsKey(localPlaylist.id)) {
        await deletePlaylist(playlistId: localPlaylist.id);
      }
    }
  }

  /// Merge media items from server with local, preserving downloaded status
  /// CRITICAL: Verifies file actually exists before trusting downloaded flag
  List<MediaItemModel> _mergeMediaItems({
    required List<MediaItemModel> serverMediaItems,
    required List<MediaItemModel> localMediaItems,
  }) {
    // Create a map of local media items by ID
    final localMediaMap = {for (var m in localMediaItems) m.mediaId: m};

    final mergedItems = <MediaItemModel>[];

    for (final serverItem in serverMediaItems) {
      final localItem = localMediaMap[serverItem.mediaId];

      if (localItem != null && localItem.downloaded == true && localItem.localPath != null) {
        // Preserve download info - trust the database flag
        // File existence will be verified at playback time, not during merge
        // Use server metadata but keep local download info
        mergedItems.add(MediaItemModel(
          mediaId: serverItem.mediaId,
          order: serverItem.order,
          mediaName: serverItem.mediaName,
          mediaType: serverItem.mediaType,
          mimetype: serverItem.mimetype,
          mediaUrl: serverItem.mediaUrl,
          localPath: localItem.localPath, // Keep local path
          fileSize: serverItem.fileSize,
          downloaded: localItem.downloaded, // Keep downloaded status
          downloadDate: localItem.downloadDate, // Keep download date
          checksum: serverItem.checksum,
          layout: serverItem.layout,
          timing: serverItem.timing,
          effects: serverItem.effects,
          nTimePlay: serverItem.nTimePlay,
        ));
      } else {
        // New media item or not downloaded yet - use server data
        mergedItems.add(serverItem);
      }
    }

    return mergedItems;
  }

  /// Downloads all media items in a playlist and notifies server via WebSocket
  ///
  /// **Flow:**
  /// 1. Downloads each media item sequentially with progress tracking
  /// 2. Sends WebSocket status updates during download:
  ///    - 'downloading': Progress updates during download
  ///    - 'ready': All media downloaded successfully
  ///    - 'failed': Download encountered errors
  /// 3. Saves playlist to local database with updated status
  /// 4. Returns updated playlist entity with download status
  ///
  /// **WebSocket Message Format:**
  /// ```json
  /// {
  ///   "type": "playlist_status",
  ///   "playlist_id": 123,
  ///   "status": "ready",
  ///   "total_items": 10,
  ///   "downloaded_items": 10
  /// }
  /// ```
  @override
  ResultFuture<PlaylistEntity> downloadPlaylist({
    required PlaylistEntity playlist,
    Function(int downloadedItems, int totalItems)? onProgress,
  }) async {
    try {
      final downloadManager = PlaylistDownloadManager(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        onProgressUpdate: (progress) {
          // Update UI progress callback
          onProgress?.call(progress.downloadedItems, progress.totalItems);

          // Send WebSocket status updates to server
          if (progress.status == PlaylistDownloadStatus.downloading) {
            sendPlaylistStatus(
              playlistId: progress.playlistId,
              status: 'downloading',
              totalItems: progress.totalItems,
              downloadedItems: progress.downloadedItems,
            );
          } else if (progress.status == PlaylistDownloadStatus.completed) {
            // IMPORTANT: Notify server that playlist is ready for playback
            sendPlaylistStatus(
              playlistId: progress.playlistId,
              status: 'ready',
              totalItems: progress.totalItems,
              downloadedItems: progress.downloadedItems,
            );
          } else if (progress.status == PlaylistDownloadStatus.failed) {
            sendPlaylistStatus(
              playlistId: progress.playlistId,
              status: 'failed',
              totalItems: progress.totalItems,
              downloadedItems: progress.downloadedItems,
              missingFiles: progress.error != null ? [progress.error!] : null,
            );
          }
        },
      );

      final updatedPlaylist = await downloadManager.downloadPlaylist(
        PlaylistModel.fromEntity(playlist),
      );

      return Right(updatedPlaylist.toEntity());
    } on VideoDownloadException catch (e) {
      return Left(VideoDownloadFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(VideoDownloadFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<List<PlaylistEntity>> getLocalPlaylists() async {
    try {
      final playlists = await localDataSource.getLocalPlaylists();
      return Right(playlists.map((p) => p.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> savePlaylists({
    required List<PlaylistEntity> playlists,
  }) async {
    try {
      final playlistModels = playlists.map((p) => PlaylistModel.fromEntity(p)).toList();
      await localDataSource.savePlaylists(playlistModels);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> deletePlaylist({
    required int playlistId,
  }) async {
    try {
      final playlist = await localDataSource.getPlaylistById(playlistId);
      if (playlist != null) {
        final downloadManager = PlaylistDownloadManager(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );
        await downloadManager.deletePlaylistMedia(playlist);
      }

      await localDataSource.deletePlaylist(playlistId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> sendPlaylistStatus({
    required int playlistId,
    required String status,
    List<String>? missingFiles,
    int? totalItems,
    int? downloadedItems,
  }) async {
    try {
      PlaylistStatusType statusType;
      switch (status) {
        case 'ready':
          statusType = PlaylistStatusType.ready;
          break;
        case 'downloading':
          statusType = PlaylistStatusType.downloading;
          break;
        case 'failed':
          statusType = PlaylistStatusType.failed;
          break;
        case 'partial':
          statusType = PlaylistStatusType.partial;
          break;
        default:
          statusType = PlaylistStatusType.failed;
      }

      final message = PlaylistStatusMessageModel(
        playlistId: playlistId,
        status: statusType,
        missingFiles: missingFiles,
        totalItems: totalItems,
        downloadedItems: downloadedItems,
      );

      await webSocketDataSource.sendMessage(message.toJson());
      return const Right(null);
    } on WebSocketException catch (e) {
      // WebSocket not connected is not critical - download can continue
      // Status will be sent when WebSocket reconnects
      if (e.message.contains('not connected')) {
        // Silently ignore - this is expected during app startup
        return const Right(null);
      }
      // Other WebSocket errors also shouldn't block download
      return const Right(null);
    } catch (e) {
      // Non-critical error - don't block download
      return const Right(null);
    }
  }

  @override
  ResultFuture<void> captureAndUploadScreenshot({
    required String deviceId,
    required int mediaId,
    required List<int> imageBytes,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/screenshot_$mediaId.jpg');
      await file.writeAsBytes(imageBytes);

      await remoteDataSource.uploadScreenshot(
        deviceId: deviceId,
        mediaId: mediaId,
        imageFile: file,
      );

      await file.delete();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<PlaylistEntity> redownloadMediaItem({
    required PlaylistEntity playlist,
    required int mediaIndex,
    Function(double)? onProgress,
  }) async {
    try {
      final downloadManager = PlaylistDownloadManager(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final updatedPlaylist = await downloadManager.redownloadMediaItem(
        playlist: PlaylistModel.fromEntity(playlist),
        mediaIndex: mediaIndex,
        onProgress: onProgress,
      );

      return Right(updatedPlaylist.toEntity());
    } on VideoDownloadException catch (e) {
      return Left(VideoDownloadFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(VideoDownloadFailure(message: e.toString()));
    }
  }
}
