import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/repositories/auth_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class LogoutUseCase extends UseCaseWithoutParams<void> {
  final AuthRepository repository;

  LogoutUseCase({required this.repository});

  @override
  ResultFuture<void> call() async {
    return await repository.logout();
  }
}
