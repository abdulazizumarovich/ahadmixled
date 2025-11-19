part of 'websocket_bloc.dart';

abstract class WebSocketEvent extends Equatable {
  const WebSocketEvent();

  @override
  List<Object?> get props => [];
}

class ConnectWebSocket extends WebSocketEvent {
  final String deviceId;
  final String accessToken;

  const ConnectWebSocket({
    required this.deviceId,
    required this.accessToken,
  });

  @override
  List<Object?> get props => [deviceId, accessToken];
}

class DisconnectWebSocket extends WebSocketEvent {
  const DisconnectWebSocket();
}

class WebSocketMessageReceived extends WebSocketEvent {
  final WebSocketMessageEntity message;

  const WebSocketMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}
