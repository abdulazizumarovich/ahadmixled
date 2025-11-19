import 'package:tv_monitor/core/utils/typedef.dart';

abstract class UseCase<Type, Params> {
  const UseCase();
  ResultFuture<Type> call(Params params);
}

abstract class UseCaseWithoutParams<Type> {
  const UseCaseWithoutParams();
  ResultFuture<Type> call();
}

abstract class StreamUseCase<Type, Params> {
  const StreamUseCase();
  Stream<Type> call(Params params);
}
