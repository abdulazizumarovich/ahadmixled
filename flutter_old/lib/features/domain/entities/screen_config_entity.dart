import 'package:equatable/equatable.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';

class ScreenConfigEntity extends Equatable {
  final int screenId;
  final String screenName;
  final String resolution;
  final int? currentPlaylist;
  final List<PlaylistEntity> playlists;

  const ScreenConfigEntity({
    required this.screenId,
    required this.screenName,
    required this.resolution,
    this.currentPlaylist,
    required this.playlists,
  });

  ScreenConfigEntity copyWith({
    int? screenId,
    String? screenName,
    String? resolution,
    int? currentPlaylist,
    List<PlaylistEntity>? playlists,
  }) {
    return ScreenConfigEntity(
      screenId: screenId ?? this.screenId,
      screenName: screenName ?? this.screenName,
      resolution: resolution ?? this.resolution,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      playlists: playlists ?? this.playlists,
    );
  }

  @override
  List<Object?> get props => [screenId, screenName, resolution, currentPlaylist, playlists];
}
