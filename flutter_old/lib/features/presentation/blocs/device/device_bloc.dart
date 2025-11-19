import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tv_monitor/features/domain/entities/device_entity.dart';
import 'package:tv_monitor/features/domain/usecases/device/get_device_info_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/device/register_device_usecase.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final GetDeviceInfoUseCase getDeviceInfoUseCase;
  final RegisterDeviceUseCase registerDeviceUseCase;

  DeviceBloc({required this.getDeviceInfoUseCase, required this.registerDeviceUseCase}) : super(const DeviceInitial()) {
    on<GetDeviceInfo>(_onGetDeviceInfo);
    on<RegisterDevice>(_onRegisterDevice);
  }

  Future<void> _onGetDeviceInfo(GetDeviceInfo event, Emitter<DeviceState> emit) async {
    emit(const DeviceLoading());

    final result = await getDeviceInfoUseCase();

    result.fold(
      (failure) => emit(DeviceError(message: failure.message)),
      (deviceInfo) => emit(DeviceInfoLoaded(deviceInfo: deviceInfo)),
    );
  }

  Future<void> _onRegisterDevice(RegisterDevice event, Emitter<DeviceState> emit) async {
    emit(const DeviceLoading());

    final result = await registerDeviceUseCase(RegisterDeviceParams(deviceInfo: event.deviceInfo));

    result.fold(
      (failure) => emit(DeviceError(message: failure.message)),
      (deviceId) => emit(DeviceRegistered(deviceId: deviceId)),
    );
  }
}
