import 'package:tv_monitor/core/utils/typedef.dart';

abstract class PermissionRepository {
  ResultFuture<bool> requestStoragePermission();

  ResultFuture<bool> isStoragePermissionGranted();

  ResultFuture<void> savePermissionStatus(bool isGranted);

  ResultFuture<bool> getSavedPermissionStatus();
}
