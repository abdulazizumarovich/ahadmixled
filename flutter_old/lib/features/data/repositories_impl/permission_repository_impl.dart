import 'package:dartz/dartz.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/errors/failures.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/datasources/local/permission_local_datasource.dart';
import 'package:tv_monitor/features/domain/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionLocalDataSource localDataSource;

  PermissionRepositoryImpl({required this.localDataSource});

  @override
  ResultFuture<bool> requestStoragePermission() async {
    try {
      final isGranted = await localDataSource.requestStoragePermission();
      return Right(isGranted);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } catch (e) {
      return Left(PermissionFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<bool> isStoragePermissionGranted() async {
    try {
      final isGranted = await localDataSource.isStoragePermissionGranted();
      return Right(isGranted);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } catch (e) {
      return Left(PermissionFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> savePermissionStatus(bool isGranted) async {
    try {
      await localDataSource.savePermissionStatus(isGranted);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<bool> getSavedPermissionStatus() async {
    try {
      final isGranted = await localDataSource.getSavedPermissionStatus();
      return Right(isGranted);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
