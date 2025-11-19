import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';
import 'package:tv_monitor/features/domain/repositories/auth_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class LoginUseCase extends UseCase<AuthEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  @override
  ResultFuture<AuthEntity> call(LoginParams params) async {
    return await repository.login(username: params.username, password: params.password);
  }
}

class LoginParams extends Equatable {
  final String username;
  final String password;

  const LoginParams({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}
