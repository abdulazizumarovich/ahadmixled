import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/media_timing_entity.dart';

part 'media_timing_model.g.dart';

@embedded
class MediaTimingModel {
  late int startTime;
  late int duration;
  late bool loop;

  MediaTimingModel({this.startTime = 0, this.duration = 0, this.loop = false});

  factory MediaTimingModel.fromJson(DataMap json) {
    return MediaTimingModel(
      startTime: json['start_time'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      loop: json['loop'] as bool? ?? false,
    );
  }

  DataMap toJson() {
    return {'start_time': startTime, 'duration': duration, 'loop': loop};
  }

  MediaTimingEntity toEntity() {
    return MediaTimingEntity(startTime: startTime, duration: duration, loop: loop);
  }

  factory MediaTimingModel.fromEntity(MediaTimingEntity entity) {
    return MediaTimingModel(startTime: entity.startTime, duration: entity.duration, loop: entity.loop);
  }
}
