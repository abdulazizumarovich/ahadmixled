import 'package:dartz/dartz.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/errors/failures.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/datasources/local/auth_local_datasource.dart';
import 'package:tv_monitor/features/data/datasources/remote/auth_remote_datasource.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';
import 'package:tv_monitor/features/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  ResultFuture<AuthEntity> login({required String username, required String password}) async {
    try {
      final result = await remoteDataSource.login(username: username, password: password);

      await localDataSource.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiresIn: result.expiresIn,
      );

      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<AuthEntity> refreshToken({required String refreshToken}) async {
    try {
      final result = await remoteDataSource.refreshToken(refreshToken: refreshToken);

      await localDataSource.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiresIn: result.expiresIn,
      );

      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> logout() async {
    try {
      await localDataSource.clearTokens();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<String?> getAccessToken() async {
    try {
      final token = await localDataSource.getAccessToken();
      return Right(token);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<String?> getRefreshToken() async {
    try {
      final token = await localDataSource.getRefreshToken();
      return Right(token);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<bool> isTokenExpired() async {
    try {
      final expired = await localDataSource.isTokenExpired();
      return Right(expired);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      await localDataSource.saveTokens(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
