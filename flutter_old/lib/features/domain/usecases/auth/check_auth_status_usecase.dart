import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';
import 'package:tv_monitor/features/domain/repositories/auth_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

class CheckAuthStatusUseCase implements UseCaseWithoutParams<AuthEntity?> {
  final AuthRepository repository;

  CheckAuthStatusUseCase({required this.repository});

  @override
  ResultFuture<AuthEntity?> call() async {
    // Check if token exists
    final accessTokenResult = await repository.getAccessToken();
    final refreshTokenResult = await repository.getRefreshToken();

    return accessTokenResult.fold((failure) => Left(failure), (accessToken) {
      if (accessToken == null) {
        // No token, user not authenticated
        return const Right(null);
      }

      return refreshTokenResult.fold((failure) => Left(failure), (refreshToken) async {
        if (refreshToken == null) {
          // No refresh token, user not authenticated
          return const Right(null);
        }

        // Check if token is expired
        final isExpiredResult = await repository.isTokenExpired();

        return isExpiredResult.fold((failure) => Left(failure), (isExpired) async {
          if (isExpired) {
            // Token expired, try to refresh
            final refreshResult = await repository.refreshToken(refreshToken: refreshToken);

            return refreshResult.fold(
              (failure) => const Right(null), // Refresh failed, not authenticated
              (auth) => Right(auth), // Refresh successful
            );
          } else {
            // Token still valid
            return Right(
              AuthEntity(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: 0, // We don't need this for auto-login
              ),
            );
          }
        });
      });
    });
  }
}
