import 'package:equatable/equatable.dart';

class DeviceEntity extends Equatable {
  final String snNumber;
  final String brand;
  final String model;
  final String manufacturer;
  final String osVersion;
  final String screenResolution;
  final String totalStorage;
  final String freeStorage;
  final String? macAddress;
  final String appVersion;
  final String? ipAddress;
  final int brightness;
  final int volume;

  const DeviceEntity({
    required this.snNumber,
    required this.brand,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.screenResolution,
    required this.totalStorage,
    required this.freeStorage,
    this.macAddress,
    required this.appVersion,
    this.ipAddress,
    this.brightness = 50,
    this.volume = 50,
  });

  @override
  List<Object?> get props => [
        snNumber,
        brand,
        model,
        manufacturer,
        osVersion,
        screenResolution,
        totalStorage,
        freeStorage,
        macAddress,
        appVersion,
        ipAddress,
        brightness,
        volume,
      ];
}
