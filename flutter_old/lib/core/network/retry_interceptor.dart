import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';

/// Dio interceptor that automatically retries failed requests with exponential backoff
class RetryInterceptor extends Interceptor {
  final Dio dio;

  // Retry configuration
  static const int maxRetries = 3;
  static const int initialDelayMs = 1000; // 1 second
  static const int maxDelayMs = 10000; // 10 seconds

  RetryInterceptor({required this.dio});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retry_count'] ?? 0;

    // Check if we should retry this error
    if (_shouldRetry(err) && retryCount < maxRetries) {
      final newRetryCount = retryCount + 1;
      final delay = _calculateDelay(newRetryCount);

      AppLogger.networkInfo(
        '🔄 Retrying request ($newRetryCount/$maxRetries) after ${delay}ms delay: ${err.requestOptions.path}',
      );

      // Wait before retrying
      await Future.delayed(Duration(milliseconds: delay));

      try {
        // Clone request with updated retry count
        final options = err.requestOptions;
        options.extra['retry_count'] = newRetryCount;

        // Retry the request
        final response = await dio.fetch(options);

        AppLogger.networkInfo(
          '✅ Request succeeded after retry $newRetryCount: ${err.requestOptions.path}',
        );

        return handler.resolve(response);
      } on DioException catch (e) {
        // If retry also fails, pass the error to next interceptor
        return super.onError(e, handler);
      }
    }

    // If we shouldn't retry or max retries reached, pass error to next handler
    if (retryCount >= maxRetries) {
      AppLogger.networkError(
        '❌ Max retries ($maxRetries) reached for: ${err.requestOptions.path}',
      );
    }

    return super.onError(err, handler);
  }

  /// Determine if the error should trigger a retry
  bool _shouldRetry(DioException err) {
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific HTTP status codes
    if (err.response != null) {
      final statusCode = err.response!.statusCode;

      // Retry on server errors (5xx) and specific client errors
      if (statusCode != null && (
          statusCode >= 500 || // Server errors
          statusCode == 408 || // Request Timeout
          statusCode == 429 || // Too Many Requests
          statusCode == 502 || // Bad Gateway
          statusCode == 503 || // Service Unavailable
          statusCode == 504    // Gateway Timeout
      )) {
        return true;
      }
    }

    // Retry on socket exceptions
    if (err.error is SocketException) {
      return true;
    }

    return false;
  }

  /// Calculate exponential backoff delay
  int _calculateDelay(int retryCount) {
    // Exponential backoff: 1s, 2s, 4s, 8s, capped at maxDelayMs
    final delay = initialDelayMs * (1 << (retryCount - 1));
    return delay > maxDelayMs ? maxDelayMs : delay;
  }
}
