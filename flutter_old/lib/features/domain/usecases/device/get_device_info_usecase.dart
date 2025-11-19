import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/device_entity.dart';
import 'package:tv_monitor/features/domain/repositories/device_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class GetDeviceInfoUseCase extends UseCaseWithoutParams<DeviceEntity> {
  final DeviceRepository repository;

  GetDeviceInfoUseCase({required this.repository});

  @override
  ResultFuture<DeviceEntity> call() async {
    return await repository.getDeviceInfo();
  }
}
