import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/device_screens_entity.dart';
import 'package:tv_monitor/features/domain/repositories/video_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class GetDeviceScreensUseCase extends UseCase<DeviceScreensEntity, String> {
  final VideoRepository _repository;

  GetDeviceScreensUseCase(this._repository);

  @override
  ResultFuture<DeviceScreensEntity> call(String params) async {
    return _repository.getDeviceScreens(deviceId: params);
  }
}
