import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/media_layout_entity.dart';

part 'media_layout_model.g.dart';

@embedded
class MediaLayoutModel {
  late int x;
  late int y;
  late int width;
  late int height;
  late int zIndex;

  MediaLayoutModel({this.x = 0, this.y = 0, this.width = 0, this.height = 0, this.zIndex = 0});

  factory MediaLayoutModel.fromJson(DataMap json) {
    return MediaLayoutModel(
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      zIndex: json['z_index'] as int? ?? 0,
    );
  }

  DataMap toJson() {
    return {'x': x, 'y': y, 'width': width, 'height': height, 'z_index': zIndex};
  }

  MediaLayoutEntity toEntity() {
    return MediaLayoutEntity(x: x, y: y, width: width, height: height, zIndex: zIndex);
  }

  factory MediaLayoutModel.fromEntity(MediaLayoutEntity entity) {
    return MediaLayoutModel(
      x: entity.x,
      y: entity.y,
      width: entity.width,
      height: entity.height,
      zIndex: entity.zIndex,
    );
  }
}
