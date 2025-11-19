part of 'device_bloc.dart';

abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {
  const DeviceInitial();
}

class DeviceLoading extends DeviceState {
  const DeviceLoading();
}

class DeviceInfoLoaded extends DeviceState {
  final DeviceEntity deviceInfo;

  const DeviceInfoLoaded({required this.deviceInfo});

  @override
  List<Object?> get props => [deviceInfo];
}

class DeviceRegistered extends DeviceState {
  final String deviceId;

  const DeviceRegistered({required this.deviceId});

  @override
  List<Object?> get props => [deviceId];
}

class DeviceError extends DeviceState {
  final String message;

  const DeviceError({required this.message});

  @override
  List<Object?> get props => [message];
}
