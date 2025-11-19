import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/repositories/permission_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class RequestPermissionUseCase extends UseCaseWithoutParams<bool> {
  final PermissionRepository repository;

  RequestPermissionUseCase({required this.repository});

  @override
  ResultFuture<bool> call() async {
    return await repository.requestStoragePermission();
  }
}
