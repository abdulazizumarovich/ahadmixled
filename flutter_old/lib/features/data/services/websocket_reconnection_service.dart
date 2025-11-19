import 'dart:async';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/datasources/remote/websocket_datasource.dart';

/// WebSocket auto-reconnection service with exponential backoff
class WebSocketReconnectionService {
  final WebSocketDataSource webSocketDataSource;

  String? _deviceId;
  String? _accessToken;
  bool _isReconnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Exponential backoff configuration
  static const int _initialDelaySeconds = 2;
  static const int _maxDelaySeconds = 60;
  static const int _pingIntervalSeconds = 30;

  WebSocketReconnectionService({required this.webSocketDataSource});

  /// Connect to WebSocket with auto-reconnection
  Future<void> connect({required String deviceId, required String accessToken}) async {
    _deviceId = deviceId;
    _accessToken = accessToken;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    await _performConnect();
    _startPingTimer();
  }

  /// Perform actual connection
  Future<void> _performConnect() async {
    if (_isReconnecting || !_shouldReconnect) {
      return;
    }

    try {
      AppLogger.websocketInfo('🔌 Attempting WebSocket connection... (attempt ${_reconnectAttempts + 1})');

      await webSocketDataSource.connect(deviceId: _deviceId!, accessToken: _accessToken!);

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
      _isReconnecting = false;

      AppLogger.websocketInfo('✅ WebSocket connected successfully');
    } catch (e) {
      AppLogger.websocketError('❌ WebSocket connection failed', e);
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (!_shouldReconnect || _isReconnecting) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    // Calculate delay with exponential backoff
    final delay = _calculateBackoffDelay(_reconnectAttempts);

    AppLogger.websocketInfo('⏰ Scheduling reconnection in $delay seconds (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _isReconnecting = false;
      _performConnect();
    });
  }

  /// Calculate exponential backoff delay
  int _calculateBackoffDelay(int attempt) {
    // Exponential backoff: 2, 4, 8, 16, 32, 60, 60, ...
    final delay = _initialDelaySeconds * (1 << (attempt - 1));
    return delay > _maxDelaySeconds ? _maxDelaySeconds : delay;
  }

  /// Check connection health and reconnect if needed
  void checkConnectionHealth() {
    if (!webSocketDataSource.isConnected && _shouldReconnect && !_isReconnecting) {
      AppLogger.websocketInfo('🔍 Connection health check failed, initiating reconnection');
      _scheduleReconnect();
    }
  }

  /// Start periodic ping to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: _pingIntervalSeconds), (_) => checkConnectionHealth());
  }

  /// Disconnect and stop auto-reconnection
  Future<void> disconnect() async {
    AppLogger.websocketInfo('🔌 Disconnecting WebSocket and stopping auto-reconnection');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await webSocketDataSource.disconnect();
  }

  /// Reconnect immediately (useful for manual reconnection)
  Future<void> reconnectNow() async {
    if (_deviceId == null || _accessToken == null) {
      AppLogger.websocketError('❌ Cannot reconnect: missing credentials');
      return;
    }

    AppLogger.websocketInfo('🔄 Manual reconnection requested');
    _reconnectAttempts = 0;
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    await _performConnect();
  }

  /// Update access token (useful when token is refreshed)
  void updateAccessToken(String newToken) {
    _accessToken = newToken;
    AppLogger.websocketInfo('🔑 WebSocket access token updated');
  }

  /// Dispose resources
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
  }

  // Getters
  bool get isConnected => webSocketDataSource.isConnected;
  bool get isReconnecting => _isReconnecting;
  int get reconnectAttempts => _reconnectAttempts;
}
