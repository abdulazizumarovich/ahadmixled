import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/models/media_item_model.dart';
import 'package:tv_monitor/features/data/models/media_layout_model.dart';
import 'package:tv_monitor/features/data/models/media_timing_model.dart';
import 'package:tv_monitor/features/data/models/media_effects_model.dart';
import 'package:tv_monitor/features/data/models/playback_config_model.dart';
import 'package:tv_monitor/features/data/models/playlist_status_model.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int id;

  late String name;
  late int width;
  late int height;
  late int duration;
  List<MediaItemModel> mediaItems;
  PlaybackConfigModel? playbackConfig;
  PlaylistStatusModel? status;

  PlaylistModel({
    this.id = 0,
    this.name = '',
    this.width = 0,
    this.height = 0,
    this.duration = 0,
    this.mediaItems = const [],
    this.playbackConfig,
    this.status,
  });

  factory PlaylistModel.fromJson(DataMap json) {
    return PlaylistModel(
      id: json['id'] as int,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      duration: json['duration'] as int,
      mediaItems: (json['media_items'] as List<dynamic>)
          .map((item) => MediaItemModel.fromJson(item as DataMap))
          .toList(),
      playbackConfig: PlaybackConfigModel.fromJson(json['playback_config'] as DataMap),
      status: PlaylistStatusModel.fromJson(json['status'] as DataMap),
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'duration': duration,
      'media_items': mediaItems.map((item) => item.toJson()).toList(),
      'playback_config': (playbackConfig ?? PlaybackConfigModel()).toJson(),
      'status': (status ?? PlaylistStatusModel()).toJson(),
    };
  }

  PlaylistEntity toEntity() {
    return PlaylistEntity(
      id: id,
      name: name,
      width: width,
      height: height,
      duration: duration,
      mediaItems: mediaItems.map((item) => item.toEntity()).toList(),
      playbackConfig: (playbackConfig ?? PlaybackConfigModel()).toEntity(),
      status: (status ?? PlaylistStatusModel()).toEntity(),
    );
  }

  factory PlaylistModel.fromEntity(PlaylistEntity entity) {
    return PlaylistModel(
      id: entity.id,
      name: entity.name,
      width: entity.width,
      height: entity.height,
      duration: entity.duration,
      mediaItems: entity.mediaItems.map((item) => MediaItemModel.fromEntity(item)).toList(),
      playbackConfig: PlaybackConfigModel.fromEntity(entity.playbackConfig),
      status: PlaylistStatusModel.fromEntity(entity.status),
    );
  }
}
