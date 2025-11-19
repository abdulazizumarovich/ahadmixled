import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/playback_config_entity.dart';

part 'playback_config_model.g.dart';

@embedded
class PlaybackConfigModel {
  late bool repeat;
  late int repeatCount;
  late String backgroundColor;

  PlaybackConfigModel({this.repeat = true, this.repeatCount = 1, this.backgroundColor = '#000000'});

  factory PlaybackConfigModel.fromJson(DataMap json) {
    return PlaybackConfigModel(
      repeat: json['repeat'] as bool? ?? true,
      repeatCount: json['repeat_count'] as int? ?? 1,
      backgroundColor: json['background_color'] as String? ?? '#000000',
    );
  }

  DataMap toJson() {
    return {'repeat': repeat, 'repeat_count': repeatCount, 'background_color': backgroundColor};
  }

  PlaybackConfigEntity toEntity() {
    return PlaybackConfigEntity(repeat: repeat, repeatCount: repeatCount, backgroundColor: backgroundColor);
  }

  factory PlaybackConfigModel.fromEntity(PlaybackConfigEntity entity) {
    return PlaybackConfigModel(
      repeat: entity.repeat,
      repeatCount: entity.repeatCount,
      backgroundColor: entity.backgroundColor,
    );
  }
}
