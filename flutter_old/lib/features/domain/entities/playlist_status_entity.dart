import 'package:equatable/equatable.dart';

class PlaylistStatusEntity extends Equatable {
  final bool isReady;
  final bool allDownloaded;
  final List<String> missingFiles;
  final DateTime? lastVerified;

  const PlaylistStatusEntity({
    required this.isReady,
    required this.allDownloaded,
    required this.missingFiles,
    this.lastVerified,
  });

  PlaylistStatusEntity copyWith({
    bool? isReady,
    bool? allDownloaded,
    List<String>? missingFiles,
    DateTime? lastVerified,
  }) {
    return PlaylistStatusEntity(
      isReady: isReady ?? this.isReady,
      allDownloaded: allDownloaded ?? this.allDownloaded,
      missingFiles: missingFiles ?? this.missingFiles,
      lastVerified: lastVerified ?? this.lastVerified,
    );
  }

  @override
  List<Object?> get props => [isReady, allDownloaded, missingFiles, lastVerified];
}
