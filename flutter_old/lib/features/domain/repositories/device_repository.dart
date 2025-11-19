import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/device_entity.dart';

abstract class DeviceRepository {
  ResultFuture<DeviceEntity> getDeviceInfo();

  ResultFuture<String> registerDevice({required DeviceEntity deviceInfo});

  ResultFuture<String?> getSavedDeviceId();

  ResultFuture<void> saveDeviceId(String deviceId);
}
