import 'package:tv_monitor/core/utils/typedef.dart';

enum PlaylistStatusType {
  ready,
  downloading,
  failed,
  partial,
}

class PlaylistStatusMessageModel {
  final int playlistId;
  final PlaylistStatusType status;
  final List<String>? missingFiles;
  final int? totalItems;
  final int? downloadedItems;
  final String? error;

  const PlaylistStatusMessageModel({
    required this.playlistId,
    required this.status,
    this.missingFiles,
    this.totalItems,
    this.downloadedItems,
    this.error,
  });

  DataMap toJson() {
    String statusStr;
    switch (status) {
      case PlaylistStatusType.ready:
        statusStr = 'ready';
        break;
      case PlaylistStatusType.downloading:
        statusStr = 'downloading';
        break;
      case PlaylistStatusType.failed:
        statusStr = 'failed';
        break;
      case PlaylistStatusType.partial:
        statusStr = 'partial';
        break;
    }

    final json = <String, dynamic>{
      'type': 'playlist_status',
      'playlist_id': playlistId,
      'status': statusStr,
    };

    if (missingFiles != null && missingFiles!.isNotEmpty) {
      json['missing_files'] = missingFiles;
    }

    if (totalItems != null) {
      json['total_items'] = totalItems;
    }

    if (downloadedItems != null) {
      json['downloaded_items'] = downloadedItems;
    }

    if (error != null) {
      json['error'] = error;
    }

    return json;
  }

  factory PlaylistStatusMessageModel.fromJson(DataMap json) {
    final statusStr = json['status'] as String;
    PlaylistStatusType status;

    switch (statusStr) {
      case 'ready':
        status = PlaylistStatusType.ready;
        break;
      case 'downloading':
        status = PlaylistStatusType.downloading;
        break;
      case 'failed':
        status = PlaylistStatusType.failed;
        break;
      case 'partial':
        status = PlaylistStatusType.partial;
        break;
      default:
        status = PlaylistStatusType.failed;
    }

    return PlaylistStatusMessageModel(
      playlistId: json['playlist_id'] as int,
      status: status,
      missingFiles: (json['missing_files'] as List<dynamic>?)?.map((e) => e as String).toList(),
      totalItems: json['total_items'] as int?,
      downloadedItems: json['downloaded_items'] as int?,
      error: json['error'] as String?,
    );
  }
}
