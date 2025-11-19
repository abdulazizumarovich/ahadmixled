import 'package:dartz/dartz.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/errors/failures.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/datasources/local/device_local_datasource.dart';
import 'package:tv_monitor/features/data/datasources/remote/device_remote_datasource.dart';
import 'package:tv_monitor/features/data/models/device_model.dart';
import 'package:tv_monitor/features/domain/entities/device_entity.dart';
import 'package:tv_monitor/features/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource remoteDataSource;
  final DeviceLocalDataSource localDataSource;

  DeviceRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  ResultFuture<DeviceEntity> getDeviceInfo() async {
    try {
      final deviceInfo = await localDataSource.getDeviceInfo();
      return Right(deviceInfo.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<String> registerDevice({required DeviceEntity deviceInfo}) async {
    try {
      final deviceModel = DeviceModel.fromEntity(deviceInfo);
      final deviceId = await remoteDataSource.registerDevice(deviceInfo: deviceModel);
      await localDataSource.saveDeviceId(deviceId);
      return Right(deviceId);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<String?> getSavedDeviceId() async {
    try {
      final deviceId = await localDataSource.getSavedDeviceId();
      return Right(deviceId);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> saveDeviceId(String deviceId) async {
    try {
      await localDataSource.saveDeviceId(deviceId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
