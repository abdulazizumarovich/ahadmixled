import 'package:isar/isar.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/playlist_status_entity.dart';

part 'playlist_status_model.g.dart';

@embedded
class PlaylistStatusModel {
  late bool isReady;
  late bool allDownloaded;
  List<String> missingFiles;
  DateTime? lastVerified;

  PlaylistStatusModel({
    this.isReady = false,
    this.allDownloaded = false,
    this.missingFiles = const [],
    this.lastVerified,
  });

  factory PlaylistStatusModel.fromJson(DataMap json) {
    return PlaylistStatusModel(
      isReady: json['is_ready'] as bool? ?? false,
      allDownloaded: json['all_downloaded'] as bool? ?? false,
      missingFiles: (json['missing_files'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      lastVerified: json['last_verified'] != null ? DateTime.parse(json['last_verified'] as String) : null,
    );
  }

  DataMap toJson() {
    return {
      'is_ready': isReady,
      'all_downloaded': allDownloaded,
      'missing_files': missingFiles,
      if (lastVerified != null) 'last_verified': lastVerified!.toIso8601String(),
    };
  }

  PlaylistStatusEntity toEntity() {
    return PlaylistStatusEntity(
      isReady: isReady,
      allDownloaded: allDownloaded,
      missingFiles: missingFiles,
      lastVerified: lastVerified,
    );
  }

  factory PlaylistStatusModel.fromEntity(PlaylistStatusEntity entity) {
    return PlaylistStatusModel(
      isReady: entity.isReady,
      allDownloaded: entity.allDownloaded,
      missingFiles: entity.missingFiles,
      lastVerified: entity.lastVerified,
    );
  }
}
