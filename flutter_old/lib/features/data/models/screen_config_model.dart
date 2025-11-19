import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/models/playlist_model.dart';
import 'package:tv_monitor/features/domain/entities/screen_config_entity.dart';

class ScreenConfigModel {
  final int screenId;
  final String screenName;
  final String resolution;
  final int? currentPlaylist;
  final List<PlaylistModel> playlists;

  ScreenConfigModel({
    required this.screenId,
    required this.screenName,
    required this.resolution,
    this.currentPlaylist,
    required this.playlists,
  });

  factory ScreenConfigModel.fromJson(DataMap json) {
    return ScreenConfigModel(
      screenId: json['screen_id'] as int,
      screenName: json['screen_name'] as String,
      resolution: json['resolution'] as String,
      currentPlaylist: json['current_playlist'] as int?,
      playlists: (json['playlists'] as List<dynamic>).map((item) => PlaylistModel.fromJson(item as DataMap)).toList(),
    );
  }

  DataMap toJson() {
    return {
      'screen_id': screenId,
      'screen_name': screenName,
      'resolution': resolution,
      'current_playlist': currentPlaylist,
      'playlists': playlists.map((p) => p.toJson()).toList(),
    };
  }

  ScreenConfigEntity toEntity() {
    return ScreenConfigEntity(
      screenId: screenId,
      screenName: screenName,
      resolution: resolution,
      currentPlaylist: currentPlaylist,
      playlists: playlists.map((p) => p.toEntity()).toList(),
    );
  }

  factory ScreenConfigModel.fromEntity(ScreenConfigEntity entity) {
    return ScreenConfigModel(
      screenId: entity.screenId,
      screenName: entity.screenName,
      resolution: entity.resolution,
      currentPlaylist: entity.currentPlaylist,
      playlists: entity.playlists.map((p) => PlaylistModel.fromEntity(p)).toList(),
    );
  }
}
