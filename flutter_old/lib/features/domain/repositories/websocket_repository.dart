import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';

abstract class WebSocketRepository {
  ResultFuture<void> connect({required String deviceId, required String accessToken});

  Stream<WebSocketMessageEntity> get messages;

  ResultFuture<void> disconnect();

  ResultFuture<bool> get isConnected;

  ResultFuture<void> sendMessage(DataMap message);
}
