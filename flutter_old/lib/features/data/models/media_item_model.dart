import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/models/media_layout_model.dart';
import 'package:tv_monitor/features/data/models/media_timing_model.dart';
import 'package:tv_monitor/features/data/models/media_effects_model.dart';
import 'package:tv_monitor/features/domain/entities/media_item_entity.dart';

part 'media_item_model.g.dart';

@embedded
class MediaItemModel {
  late int mediaId;
  late int order;
  late String mediaName;
  late String mediaType;
  late String mimetype;
  late String mediaUrl;
  String? localPath;
  late int fileSize;
  late bool downloaded;
  DateTime? downloadDate;
  late String checksum;
  MediaLayoutModel? layout;
  MediaTimingModel? timing;
  MediaEffectsModel? effects;
  late int nTimePlay;

  MediaItemModel({
    this.mediaId = 0,
    this.order = 0,
    this.mediaName = '',
    this.mediaType = '',
    this.mimetype = '',
    this.mediaUrl = '',
    this.localPath,
    this.fileSize = 0,
    this.downloaded = false,
    this.downloadDate,
    this.checksum = '',
    this.layout,
    this.timing,
    this.effects,
    this.nTimePlay = 1,
  });

  factory MediaItemModel.fromJson(DataMap json) {
    return MediaItemModel(
      mediaId: json['media_id'] as int,
      order: json['order'] as int,
      mediaName: json['media_name'] as String,
      mediaType: json['media_type'] as String,
      mimetype: json['mimetype'] as String,
      mediaUrl: json['media_url'] as String,
      localPath: json['local_path'] as String?,
      fileSize: json['file_size'] as int,
      downloaded: json['downloaded'] as bool? ?? false,
      downloadDate: json['download_date'] != null ? DateTime.parse(json['download_date'] as String) : null,
      checksum: json['checksum'] as String,
      layout: MediaLayoutModel.fromJson(json['layout'] as DataMap),
      timing: MediaTimingModel.fromJson(json['timing'] as DataMap),
      effects: MediaEffectsModel.fromJson(json['effects'] as DataMap),
      nTimePlay: json['n_time_play'] as int? ?? 1,
    );
  }

  DataMap toJson() {
    return {
      'media_id': mediaId,
      'order': order,
      'media_name': mediaName,
      'media_type': mediaType,
      'mimetype': mimetype,
      'media_url': mediaUrl,
      if (localPath != null) 'local_path': localPath,
      'file_size': fileSize,
      'downloaded': downloaded,
      if (downloadDate != null) 'download_date': downloadDate!.toIso8601String(),
      'checksum': checksum,
      'layout': (layout ?? MediaLayoutModel()).toJson(),
      'timing': (timing ?? MediaTimingModel()).toJson(),
      'effects': (effects ?? MediaEffectsModel()).toJson(),
      'n_time_play': nTimePlay,
    };
  }

  MediaItemEntity toEntity() {
    return MediaItemEntity(
      mediaId: mediaId,
      order: order,
      mediaName: mediaName,
      mediaType: mediaType,
      mimetype: mimetype,
      mediaUrl: mediaUrl,
      localPath: localPath,
      fileSize: fileSize,
      downloaded: downloaded,
      downloadDate: downloadDate,
      checksum: checksum,
      layout: (layout ?? MediaLayoutModel()).toEntity(),
      timing: (timing ?? MediaTimingModel()).toEntity(),
      effects: (effects ?? MediaEffectsModel()).toEntity(),
      nTimePlay: nTimePlay,
    );
  }

  factory MediaItemModel.fromEntity(MediaItemEntity entity) {
    return MediaItemModel(
      mediaId: entity.mediaId,
      order: entity.order,
      mediaName: entity.mediaName,
      mediaType: entity.mediaType,
      mimetype: entity.mimetype,
      mediaUrl: entity.mediaUrl,
      localPath: entity.localPath,
      fileSize: entity.fileSize,
      downloaded: entity.downloaded,
      downloadDate: entity.downloadDate,
      checksum: entity.checksum,
      layout: MediaLayoutModel.fromEntity(entity.layout),
      timing: MediaTimingModel.fromEntity(entity.timing),
      effects: MediaEffectsModel.fromEntity(entity.effects),
      nTimePlay: entity.nTimePlay,
    );
  }
}
