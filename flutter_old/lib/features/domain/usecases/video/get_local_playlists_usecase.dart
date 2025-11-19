import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/playlist_entity.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class GetLocalPlaylistsUseCase extends UseCaseWithoutParams<List<PlaylistEntity>> {
  final VideoRepository _repository;

  GetLocalPlaylistsUseCase(this._repository);

  @override
  ResultFuture<List<PlaylistEntity>> call() async {
    return _repository.getLocalPlaylists();
  }
}
