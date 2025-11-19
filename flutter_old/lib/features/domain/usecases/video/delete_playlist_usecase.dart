import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class DeletePlaylistUseCase extends UseCase<void, int> {
  final VideoRepository _repository;

  DeletePlaylistUseCase(this._repository);

  @override
  ResultFuture<void> call(int params) async {
    return _repository.deletePlaylist(playlistId: params);
  }
}
