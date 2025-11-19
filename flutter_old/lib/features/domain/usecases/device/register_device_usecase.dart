import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/device_entity.dart';
import 'package:tv_monitor/features/domain/repositories/device_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class RegisterDeviceUseCase extends UseCase<String, RegisterDeviceParams> {
  final DeviceRepository repository;

  RegisterDeviceUseCase({required this.repository});

  @override
  ResultFuture<String> call(RegisterDeviceParams params) async {
    return await repository.registerDevice(deviceInfo: params.deviceInfo);
  }
}

class RegisterDeviceParams extends Equatable {
  final DeviceEntity deviceInfo;

  const RegisterDeviceParams({required this.deviceInfo});

  @override
  List<Object?> get props => [deviceInfo];
}
