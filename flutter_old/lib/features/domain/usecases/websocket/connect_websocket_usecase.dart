import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/repositories/websocket_repository.dart';
import 'package:tv_monitor/features/domain/usecases/usecase.dart';

class ConnectWebSocketUseCase extends UseCase<void, ConnectWebSocketParams> {
  final WebSocketRepository repository;

  ConnectWebSocketUseCase({required this.repository});

  @override
  ResultFuture<void> call(ConnectWebSocketParams params) async {
    return await repository.connect(deviceId: params.deviceId, accessToken: params.accessToken);
  }
}

class ConnectWebSocketParams extends Equatable {
  final String deviceId;
  final String accessToken;

  const ConnectWebSocketParams({required this.deviceId, required this.accessToken});

  @override
  List<Object?> get props => [deviceId, accessToken];
}
