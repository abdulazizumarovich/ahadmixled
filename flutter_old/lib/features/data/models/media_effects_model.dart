import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/media_effects_entity.dart';

part 'media_effects_model.g.dart';

@embedded
class MediaEffectsModel {
  late String transition;
  late int fadeDuration;

  MediaEffectsModel({this.transition = 'none', this.fadeDuration = 1000});

  factory MediaEffectsModel.fromJson(DataMap json) {
    return MediaEffectsModel(
      transition: json['transition'] as String? ?? 'none',
      fadeDuration: json['fade_duration'] as int? ?? 1000,
    );
  }

  DataMap toJson() {
    return {'transition': transition, 'fade_duration': fadeDuration};
  }

  MediaEffectsEntity toEntity() {
    return MediaEffectsEntity(transition: transition, fadeDuration: fadeDuration);
  }

  factory MediaEffectsModel.fromEntity(MediaEffectsEntity entity) {
    return MediaEffectsModel(transition: entity.transition, fadeDuration: entity.fadeDuration);
  }
}
