part of 'device_bloc.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object?> get props => [];
}

class GetDeviceInfo extends DeviceEvent {
  const GetDeviceInfo();
}

class RegisterDevice extends DeviceEvent {
  final DeviceEntity deviceInfo;

  const RegisterDevice({required this.deviceInfo});

  @override
  List<Object?> get props => [deviceInfo];
}
