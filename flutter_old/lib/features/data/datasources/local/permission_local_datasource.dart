import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_monitor/core/constants/app_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';

abstract class PermissionLocalDataSource {
  Future<bool> requestStoragePermission();

  Future<bool> isStoragePermissionGranted();

  Future<void> savePermissionStatus(bool isGranted);

  Future<bool> getSavedPermissionStatus();
}

class PermissionLocalDataSourceImpl implements PermissionLocalDataSource {
  final SharedPreferences sharedPreferences;

  PermissionLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<bool> requestStoragePermission() async {
    try {
      // For Android 13+ (API 33+), request media permissions
      // For Android 12 and below, request storage permission
      Map<Permission, PermissionStatus> statuses = {};

      // Request videos permission (covers both old and new APIs)
      statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.manageExternalStorage,
      ].request();

      // Check if all requested permissions are granted or limited
      final allGranted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      await savePermissionStatus(allGranted);
      return allGranted;
    } catch (e) {
      throw PermissionException(
        message: 'Failed to request storage permission: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isStoragePermissionGranted() async {
    try {
      final videoStatus = await Permission.videos.status;
      final manageStatus = await Permission.manageExternalStorage.status;

      // Return true if at least videos permission is granted
      return videoStatus.isGranted ||
             videoStatus.isLimited ||
             manageStatus.isGranted;
    } catch (e) {
      throw PermissionException(
        message: 'Failed to check storage permission: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> savePermissionStatus(bool isGranted) async {
    try {
      await sharedPreferences.setBool(
        AppConstants.permissionsGrantedKey,
        isGranted,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save permission status: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> getSavedPermissionStatus() async {
    try {
      return sharedPreferences.getBool(AppConstants.permissionsGrantedKey) ?? false;
    } catch (e) {
      throw CacheException(
        message: 'Failed to get saved permission status: ${e.toString()}',
      );
    }
  }
}
