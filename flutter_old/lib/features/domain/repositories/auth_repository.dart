import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  ResultFuture<AuthEntity> login({required String username, required String password});

  ResultFuture<AuthEntity> refreshToken({required String refreshToken});

  ResultFuture<void> logout();

  ResultFuture<String?> getAccessToken();

  ResultFuture<String?> getRefreshToken();

  ResultFuture<bool> isTokenExpired();

  ResultFuture<void> saveTokens({required String accessToken, required String refreshToken, required int expiresIn});
}
