import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tv_monitor/core/constants/api_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/models/websocket_message_model.dart';

abstract class WebSocketDataSource {
  Future<void> connect({required String deviceId, required String accessToken});

  Stream<WebSocketMessageModel> get messages;

  Future<void> disconnect();

  bool get isConnected;

  Future<void> sendMessage(DataMap message);
}

class WebSocketDataSourceImpl implements WebSocketDataSource {
  WebSocketChannel? _channel;
  final StreamController<WebSocketMessageModel> _messageController =
      StreamController<WebSocketMessageModel>.broadcast();
  bool _isConnected = false;

  @override
  Future<void> connect({required String deviceId, required String accessToken}) async {
    try {
      if (_isConnected) {
        AppLogger.websocketInfo('Already connected to WebSocket');
        return;
      }

      final wsUrl = ApiConstants.wsUrl(deviceId, accessToken);

      AppLogger.websocketInfo('Connecting to WebSocket for device: $deviceId');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          try {
            AppLogger.websocketInfo('📨 Raw WebSocket data received: $data');
            final json = jsonDecode(data as String) as DataMap;
            AppLogger.websocketInfo('📋 Parsed JSON: $json');
            final message = WebSocketMessageModel.fromJson(json);
            AppLogger.websocketInfo('✅ Message parsed - Action: ${message.action}, PlaylistId: ${message.playlistId}');
            _messageController.add(message);
            AppLogger.websocketInfo('📤 Message added to stream controller');
          } catch (e, stackTrace) {
            AppLogger.websocketError('❌ Error parsing WebSocket message', e);
            AppLogger.websocketError('Stack trace: $stackTrace');
          }
        },
        onError: (error) {
          _isConnected = false;
          AppLogger.websocketError('WebSocket connection error', error);
          _messageController.addError(WebSocketException(message: 'WebSocket error: $error'));
        },
        onDone: () {
          _isConnected = false;
          AppLogger.websocketInfo('WebSocket connection closed');
        },
      );

      _isConnected = true;
      AppLogger.websocketInfo('WebSocket connected successfully');
    } catch (e) {
      AppLogger.websocketError('Failed to connect to WebSocket', e);
      throw WebSocketException(message: 'Failed to connect to WebSocket: ${e.toString()}');
    }
  }

  @override
  Stream<WebSocketMessageModel> get messages => _messageController.stream;

  @override
  Future<void> disconnect() async {
    try {
      AppLogger.websocketInfo('Disconnecting WebSocket...');
      await _channel?.sink.close();
      _isConnected = false;
      AppLogger.websocketInfo('WebSocket disconnected successfully');
    } catch (e) {
      AppLogger.websocketError('Failed to disconnect WebSocket', e);
      throw WebSocketException(message: 'Failed to disconnect WebSocket: ${e.toString()}');
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> sendMessage(DataMap message) async {
    try {
      if (!_isConnected || _channel == null) {
        throw WebSocketException(message: 'WebSocket is not connected');
      }

      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      AppLogger.websocketInfo('Sent message: $jsonMessage');
    } catch (e) {
      AppLogger.websocketError('Failed to send WebSocket message', e);
      throw WebSocketException(message: 'Failed to send message: ${e.toString()}');
    }
  }
}
