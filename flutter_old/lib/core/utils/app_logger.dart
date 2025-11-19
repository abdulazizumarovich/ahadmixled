import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Auth logs
  static void authInfo(String message) {
    info('🔐 [AUTH] $message');
  }

  static void authError(String message, [dynamic error]) {
    AppLogger.error('🔐 [AUTH] $message', error);
  }

  // Device logs
  static void deviceInfo(String message) {
    info('📱 [DEVICE] $message');
  }

  static void deviceError(String message, [dynamic error]) {
    AppLogger.error('📱 [DEVICE] $message', error);
  }

  // WebSocket logs
  static void websocketInfo(String message) {
    info('🔌 [WEBSOCKET] $message');
  }

  static void websocketError(String message, [dynamic error]) {
    AppLogger.error('🔌 [WEBSOCKET] $message', error);
  }

  // Video logs
  static void videoInfo(String message) {
    info('🎬 [VIDEO] $message');
  }

  static void videoError(String message, [dynamic error]) {
    AppLogger.error('🎬 [VIDEO] $message', error);
  }

  // Network logs
  static void networkInfo(String message) {
    info('🌐 [NETWORK] $message');
  }

  static void networkError(String message, [dynamic error]) {
    AppLogger.error('🌐 [NETWORK] $message', error);
  }
}
