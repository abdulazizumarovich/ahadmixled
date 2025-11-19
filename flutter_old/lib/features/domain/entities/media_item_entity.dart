import 'package:equatable/equatable.dart';
import 'package:tv_monitor/features/domain/entities/media_layout_entity.dart';
import 'package:tv_monitor/features/domain/entities/media_timing_entity.dart';
import 'package:tv_monitor/features/domain/entities/media_effects_entity.dart';

class MediaItemEntity extends Equatable {
  final int mediaId;
  final int order;
  final String mediaName;
  final String mediaType;
  final String mimetype;
  final String mediaUrl;
  final String? localPath;
  final int fileSize;
  final bool downloaded;
  final DateTime? downloadDate;
  final String checksum;
  final MediaLayoutEntity layout;
  final MediaTimingEntity timing;
  final MediaEffectsEntity effects;
  final int nTimePlay;

  const MediaItemEntity({
    required this.mediaId,
    required this.order,
    required this.mediaName,
    required this.mediaType,
    required this.mimetype,
    required this.mediaUrl,
    this.localPath,
    required this.fileSize,
    required this.downloaded,
    this.downloadDate,
    required this.checksum,
    required this.layout,
    required this.timing,
    required this.effects,
    required this.nTimePlay,
  });

  MediaItemEntity copyWith({
    int? mediaId,
    int? order,
    String? mediaName,
    String? mediaType,
    String? mimetype,
    String? mediaUrl,
    String? localPath,
    int? fileSize,
    bool? downloaded,
    DateTime? downloadDate,
    String? checksum,
    MediaLayoutEntity? layout,
    MediaTimingEntity? timing,
    MediaEffectsEntity? effects,
    int? nTimePlay,
  }) {
    return MediaItemEntity(
      mediaId: mediaId ?? this.mediaId,
      order: order ?? this.order,
      mediaName: mediaName ?? this.mediaName,
      mediaType: mediaType ?? this.mediaType,
      mimetype: mimetype ?? this.mimetype,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      downloaded: downloaded ?? this.downloaded,
      downloadDate: downloadDate ?? this.downloadDate,
      checksum: checksum ?? this.checksum,
      layout: layout ?? this.layout,
      timing: timing ?? this.timing,
      effects: effects ?? this.effects,
      nTimePlay: nTimePlay ?? this.nTimePlay,
    );
  }

  @override
  List<Object?> get props => [
    mediaId,
    order,
    mediaName,
    mediaType,
    mimetype,
    mediaUrl,
    localPath,
    fileSize,
    downloaded,
    downloadDate,
    checksum,
    layout,
    timing,
    effects,
    nTimePlay,
  ];
}
