import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/device_entity.dart';

class DeviceModel extends DeviceEntity {
  const DeviceModel({
    required super.snNumber,
    required super.brand,
    required super.model,
    required super.manufacturer,
    required super.osVersion,
    required super.screenResolution,
    required super.totalStorage,
    required super.freeStorage,
    super.macAddress,
    required super.appVersion,
    super.ipAddress,
    super.brightness = 50,
    super.volume = 50,
  });

  factory DeviceModel.fromJson(DataMap json) {
    return DeviceModel(
      snNumber: json['sn_number'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      manufacturer: json['manufacturer'] as String,
      osVersion: json['os_version'] as String,
      screenResolution: json['screen_resolution'] as String,
      totalStorage: json['total_storage'] as String,
      freeStorage: json['free_storage'] as String,
      macAddress: json['mac_address'] as String?,
      appVersion: json['app_version'] as String,
      ipAddress: json['ip_address'] as String?,
      brightness: json['brightness'] as int? ?? 50,
      volume: json['volume'] as int? ?? 50,
    );
  }

  DataMap toJson() {
    return {
      'sn_number': snNumber,
      'brand': brand,
      'model': model,
      'manufacturer': manufacturer,
      'os_version': osVersion,
      'screen_resolution': screenResolution,
      'total_storage': totalStorage,
      'free_storage': freeStorage,
      if (macAddress != null) 'mac_address': macAddress,
      'app_version': appVersion,
      if (ipAddress != null) 'ip_address': ipAddress,
      'brightness': brightness,
      'volume': volume,
    };
  }

  DeviceEntity toEntity() {
    return DeviceEntity(
      snNumber: snNumber,
      brand: brand,
      model: model,
      manufacturer: manufacturer,
      osVersion: osVersion,
      screenResolution: screenResolution,
      totalStorage: totalStorage,
      freeStorage: freeStorage,
      macAddress: macAddress,
      appVersion: appVersion,
      ipAddress: ipAddress,
      brightness: brightness,
      volume: volume,
    );
  }

  factory DeviceModel.fromEntity(DeviceEntity entity) {
    return DeviceModel(
      snNumber: entity.snNumber,
      brand: entity.brand,
      model: entity.model,
      manufacturer: entity.manufacturer,
      osVersion: entity.osVersion,
      screenResolution: entity.screenResolution,
      totalStorage: entity.totalStorage,
      freeStorage: entity.freeStorage,
      macAddress: entity.macAddress,
      appVersion: entity.appVersion,
      ipAddress: entity.ipAddress,
      brightness: entity.brightness,
      volume: entity.volume,
    );
  }
}
