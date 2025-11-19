import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class DownloadPlaylistParams {
  final PlaylistEntity playlist;
  final Function(int downloadedItems, int totalItems)? onProgress;

  const DownloadPlaylistParams({required this.playlist, this.onProgress});
}

class DownloadPlaylistUseCase extends UseCase<PlaylistEntity, DownloadPlaylistParams> {
  final VideoRepository _repository;

  DownloadPlaylistUseCase(this._repository);

  @override
  ResultFuture<PlaylistEntity> call(DownloadPlaylistParams params) async {
    return _repository.downloadPlaylist(playlist: params.playlist, onProgress: params.onProgress);
  }
}
