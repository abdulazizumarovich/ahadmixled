import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class SendPlaylistStatusParams {
  final int playlistId;
  final String status;
  final List<String>? missingFiles;
  final int? totalItems;
  final int? downloadedItems;

  const SendPlaylistStatusParams({
    required this.playlistId,
    required this.status,
    this.missingFiles,
    this.totalItems,
    this.downloadedItems,
  });
}

class SendPlaylistStatusUseCase extends UseCase<void, SendPlaylistStatusParams> {
  final VideoRepository _repository;

  SendPlaylistStatusUseCase(this._repository);

  @override
  ResultFuture<void> call(SendPlaylistStatusParams params) async {
    return _repository.sendPlaylistStatus(
      playlistId: params.playlistId,
      status: params.status,
      missingFiles: params.missingFiles,
      totalItems: params.totalItems,
      downloadedItems: params.downloadedItems,
    );
  }
}
