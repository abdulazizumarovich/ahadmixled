import 'package:isar/isar.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/features/data/models/playlist_model.dart';

abstract class VideoLocalDataSource {
  Future<List<PlaylistModel>> getLocalPlaylists();

  Future<void> savePlaylists(List<PlaylistModel> playlists);

  Future<void> updatePlaylist(PlaylistModel playlist);

  Future<void> deletePlaylist(int playlistId);

  Future<PlaylistModel?> getPlaylistById(int playlistId);

  Future<void> clearAllPlaylists();
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final Isar isar;

  VideoLocalDataSourceImpl({required this.isar});

  @override
  Future<List<PlaylistModel>> getLocalPlaylists() async {
    try {
      return await isar.playlistModels.where().findAll();
    } catch (e) {
      throw CacheException(message: 'Failed to get local playlists: ${e.toString()}');
    }
  }

  @override
  Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    try {
      await isar.writeTxn(() async {
        await isar.playlistModels.putAll(playlists);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to save playlists: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePlaylist(PlaylistModel playlist) async {
    try {
      await isar.writeTxn(() async {
        await isar.playlistModels.put(playlist);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to update playlist: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePlaylist(int playlistId) async {
    try {
      await isar.writeTxn(() async {
        final playlist = await isar.playlistModels.filter().idEqualTo(playlistId).findFirst();
        if (playlist != null) {
          await isar.playlistModels.delete(playlist.isarId);
        }
      });
    } catch (e) {
      throw CacheException(message: 'Failed to delete playlist: ${e.toString()}');
    }
  }

  @override
  Future<PlaylistModel?> getPlaylistById(int playlistId) async {
    try {
      return await isar.playlistModels.filter().idEqualTo(playlistId).findFirst();
    } catch (e) {
      throw CacheException(message: 'Failed to get playlist by ID: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllPlaylists() async {
    try {
      await isar.writeTxn(() async {
        await isar.playlistModels.clear();
      });
    } catch (e) {
      throw CacheException(message: 'Failed to clear playlists: ${e.toString()}');
    }
  }
}
