import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';
import 'package:tv_monitor/features/domain/repositories/auth_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class RefreshTokenUseCase extends UseCase<AuthEntity, RefreshTokenParams> {
  final AuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  @override
  ResultFuture<AuthEntity> call(RefreshTokenParams params) async {
    return await repository.refreshToken(refreshToken: params.refreshToken);
  }
}

class RefreshTokenParams extends Equatable {
  final String refreshToken;

  const RefreshTokenParams({required this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];
}
