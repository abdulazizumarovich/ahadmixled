part of 'websocket_bloc.dart';

abstract class WebSocketState extends Equatable {
  const WebSocketState();

  @override
  List<Object?> get props => [];
}

class WebSocketInitial extends WebSocketState {
  const WebSocketInitial();
}

class WebSocketConnecting extends WebSocketState {
  const WebSocketConnecting();
}

class WebSocketConnected extends WebSocketState {
  const WebSocketConnected();
}

class WebSocketDisconnected extends WebSocketState {
  const WebSocketDisconnected();
}

class WebSocketError extends WebSocketState {
  final String message;

  const WebSocketError({required this.message});

  @override
  List<Object?> get props => [message];
}
