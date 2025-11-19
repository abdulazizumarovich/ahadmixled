import 'package:equatable/equatable.dart';
import 'package:tv_monitor/features/domain/entities/media_item_entity.dart';
import 'package:tv_monitor/features/domain/entities/playback_config_entity.dart';
import 'package:tv_monitor/features/domain/entities/playlist_status_entity.dart';

class PlaylistEntity extends Equatable {
  final int id;
  final String name;
  final int width;
  final int height;
  final int duration;
  final List<MediaItemEntity> mediaItems;
  final PlaybackConfigEntity playbackConfig;
  final PlaylistStatusEntity status;

  const PlaylistEntity({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.duration,
    required this.mediaItems,
    required this.playbackConfig,
    required this.status,
  });

  PlaylistEntity copyWith({
    int? id,
    String? name,
    int? width,
    int? height,
    int? duration,
    List<MediaItemEntity>? mediaItems,
    PlaybackConfigEntity? playbackConfig,
    PlaylistStatusEntity? status,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      mediaItems: mediaItems ?? this.mediaItems,
      playbackConfig: playbackConfig ?? this.playbackConfig,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, name, width, height, duration, mediaItems, playbackConfig, status];
}
