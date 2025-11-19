import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/video_entity.dart';

part 'video_model.g.dart';

@collection
class VideoModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String url;

  late int order;

  String? localPath;

  bool isDownloaded;

  VideoModel({required this.id, required this.url, required this.order, this.localPath, this.isDownloaded = false});

  factory VideoModel.fromJson(DataMap json) {
    return VideoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      localPath: json['local_path'] as String?,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'url': url,
      'order': order,
      if (localPath != null) 'local_path': localPath,
      'is_downloaded': isDownloaded,
    };
  }

  VideoEntity toEntity() {
    return VideoEntity(id: id, url: url, order: order, localPath: localPath, isDownloaded: isDownloaded);
  }

  factory VideoModel.fromEntity(VideoEntity entity) {
    return VideoModel(
      id: entity.id,
      url: entity.url,
      order: entity.order,
      localPath: entity.localPath,
      isDownloaded: entity.isDownloaded,
    );
  }

  VideoModel copyWith({String? id, String? url, int? order, String? localPath, bool? isDownloaded}) {
    return VideoModel(
      id: id ?? this.id,
      url: url ?? this.url,
      order: order ?? this.order,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
