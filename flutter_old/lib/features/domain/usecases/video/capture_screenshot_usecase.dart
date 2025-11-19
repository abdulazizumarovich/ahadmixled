import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class CaptureScreenshotUseCase extends UseCase<void, CaptureScreenshotParams> {
  final VideoRepository repository;

  CaptureScreenshotUseCase({required this.repository});

  @override
  ResultFuture<void> call(CaptureScreenshotParams params) async {
    return await repository.captureAndUploadScreenshot(
      deviceId: params.deviceId,
      mediaId: params.mediaId,
      imageBytes: params.imageBytes,
    );
  }
}

class CaptureScreenshotParams extends Equatable {
  final String deviceId;
  final int mediaId;
  final List<int> imageBytes;

  const CaptureScreenshotParams({required this.deviceId, required this.mediaId, required this.imageBytes});

  @override
  List<Object?> get props => [deviceId, mediaId, imageBytes];
}
