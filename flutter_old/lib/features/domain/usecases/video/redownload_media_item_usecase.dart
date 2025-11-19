import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class RedownloadMediaItemParams {
  final PlaylistEntity playlist;
  final int mediaIndex;
  final Function(double)? onProgress;

  const RedownloadMediaItemParams({required this.playlist, required this.mediaIndex, this.onProgress});
}

class RedownloadMediaItemUseCase extends UseCase<PlaylistEntity, RedownloadMediaItemParams> {
  final VideoRepository _repository;

  RedownloadMediaItemUseCase(this._repository);

  @override
  ResultFuture<PlaylistEntity> call(RedownloadMediaItemParams params) async {
    return _repository.redownloadMediaItem(
      playlist: params.playlist,
      mediaIndex: params.mediaIndex,
      onProgress: params.onProgress,
    );
  }
}
