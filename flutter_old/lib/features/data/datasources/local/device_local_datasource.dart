import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_monitor/core/constants/app_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/features/data/models/device_model.dart';

abstract class DeviceLocalDataSource {
  Future<DeviceModel> getDeviceInfo();

  Future<void> saveDeviceId(String snNumber);

  Future<String?> getSavedDeviceId();

  Future<void> saveBrightness(int brightness);

  Future<int> getSavedBrightness();

  Future<void> saveVolume(int volume);

  Future<int> getSavedVolume();
}

class DeviceLocalDataSourceImpl implements DeviceLocalDataSource {
  final DeviceInfoPlugin deviceInfo;
  final PackageInfo packageInfo;
  final SharedPreferences sharedPreferences;

  DeviceLocalDataSourceImpl({required this.deviceInfo, required this.packageInfo, required this.sharedPreferences});

  @override
  Future<DeviceModel> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final screenSize = await _getScreenResolution();
        final ipAddress = await _getIpAddress();
        final brightness = await getSavedBrightness();
        final volume = await getSavedVolume();

        return DeviceModel(
          snNumber: androidInfo.id,
          brand: androidInfo.brand,
          model: androidInfo.model,
          manufacturer: androidInfo.manufacturer,
          osVersion: 'Android ${androidInfo.version.release}',
          screenResolution: screenSize,
          totalStorage: await _getTotalStorage(),
          freeStorage: await _getFreeStorage(),
          macAddress: null, // MAC address retrieval is restricted in recent Android versions
          appVersion: packageInfo.version,
          ipAddress: ipAddress,
          brightness: brightness,
          volume: volume,
        );
      } else {
        throw CacheException(message: 'Unsupported platform');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to get device info: ${e.toString()}');
    }
  }

  @override
  Future<void> saveDeviceId(String snNumber) async {
    try {
      await sharedPreferences.setString(AppConstants.deviceIdKey, snNumber);
    } catch (e) {
      throw CacheException(message: 'Failed to save device ID: ${e.toString()}');
    }
  }

  @override
  Future<String?> getSavedDeviceId() async {
    try {
      return sharedPreferences.getString(AppConstants.deviceIdKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get saved device ID: ${e.toString()}');
    }
  }

  @override
  Future<void> saveBrightness(int brightness) async {
    try {
      await sharedPreferences.setInt(AppConstants.brightnessKey, brightness);
    } catch (e) {
      throw CacheException(message: 'Failed to save brightness: ${e.toString()}');
    }
  }

  @override
  Future<int> getSavedBrightness() async {
    try {
      return sharedPreferences.getInt(AppConstants.brightnessKey) ?? 50;
    } catch (e) {
      throw CacheException(message: 'Failed to get saved brightness: ${e.toString()}');
    }
  }

  @override
  Future<void> saveVolume(int volume) async {
    try {
      await sharedPreferences.setInt(AppConstants.volumeKey, volume);
    } catch (e) {
      throw CacheException(message: 'Failed to save volume: ${e.toString()}');
    }
  }

  @override
  Future<int> getSavedVolume() async {
    try {
      return sharedPreferences.getInt(AppConstants.volumeKey) ?? 50;
    } catch (e) {
      throw CacheException(message: 'Failed to get saved volume: ${e.toString()}');
    }
  }

  Future<String> _getScreenResolution() async {
    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      final physicalSize = view.physicalSize;
      final width = physicalSize.width.toInt();
      final height = physicalSize.height.toInt();
      return '${width}x$height';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getTotalStorage() async {
    try {
      final diskSpace = DiskSpacePlus();
      final totalDiskSpace = await diskSpace.getTotalDiskSpace;
      if (totalDiskSpace != null) {
        // Convert to GB with 2 decimal places
        final totalGB = (totalDiskSpace / 1024).toStringAsFixed(2);
        return '$totalGB GB';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getFreeStorage() async {
    try {
      final diskSpace = DiskSpacePlus();
      final freeDiskSpace = await diskSpace.getFreeDiskSpace;
      if (freeDiskSpace != null) {
        // Convert to GB with 2 decimal places
        final freeGB = (freeDiskSpace / 1024).toStringAsFixed(2);
        return '$freeGB GB';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String?> _getIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
