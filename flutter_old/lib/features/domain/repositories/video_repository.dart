import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/device_screens_entity.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';

abstract class VideoRepository {
  ResultFuture<DeviceScreensEntity> getDeviceScreens({required String deviceId});

  ResultFuture<PlaylistEntity> downloadPlaylist({
    required PlaylistEntity playlist,
    Function(int downloadedItems, int totalItems)? onProgress,
  });

  ResultFuture<List<PlaylistEntity>> getLocalPlaylists();

  ResultFuture<void> savePlaylists({required List<PlaylistEntity> playlists});

  ResultFuture<void> deletePlaylist({required int playlistId});

  ResultFuture<void> sendPlaylistStatus({
    required int playlistId,
    required String status,
    List<String>? missingFiles,
    int? totalItems,
    int? downloadedItems,
  });

  ResultFuture<void> captureAndUploadScreenshot({
    required String deviceId,
    required int mediaId,
    required List<int> imageBytes,
  });

  ResultFuture<PlaylistEntity> redownloadMediaItem({
    required PlaylistEntity playlist,
    required int mediaIndex,
    Function(double)? onProgress,
  });
}
