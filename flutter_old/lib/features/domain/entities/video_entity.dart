import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
  final String id;
  final String url;
  final int order;
  final String? localPath;
  final bool isDownloaded;

  const VideoEntity({
    required this.id,
    required this.url,
    required this.order,
    this.localPath,
    this.isDownloaded = false,
  });

  VideoEntity copyWith({
    String? id,
    String? url,
    int? order,
    String? localPath,
    bool? isDownloaded,
  }) {
    return VideoEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      order: order ?? this.order,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [id, url, order, localPath, isDownloaded];
}
