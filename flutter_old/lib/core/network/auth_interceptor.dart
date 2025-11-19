import 'package:dio/dio.dart';
import 'package:tv_monitor/core/constants/api_constants.dart';
import 'package:tv_monitor/features/data/datasources/local/auth_local_datasource.dart';
import 'package:tv_monitor/features/data/datasources/remote/auth_remote_datasource.dart';

class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final Dio dio;

  AuthInterceptor({required this.localDataSource, required this.remoteDataSource, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip adding token for login and refresh token endpoints
    if (options.path.contains(ApiConstants.login) || options.path.contains(ApiConstants.refreshToken)) {
      return handler.next(options);
    }

    try {
      // Get access token from local storage
      final accessToken = await localDataSource.getAccessToken();

      if (accessToken != null) {
        // Add token to request headers
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      return handler.next(options);
    } catch (e) {
      return handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      try {
        // Get refresh token
        final refreshToken = await localDataSource.getRefreshToken();

        if (refreshToken != null) {
          // Try to refresh the access token
          final authModel = await remoteDataSource.refreshToken(refreshToken: refreshToken);

          // Save new tokens
          await localDataSource.saveTokens(
            accessToken: authModel.accessToken,
            refreshToken: authModel.refreshToken,
            expiresIn: authModel.expiresIn,
          );

          // Retry the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${authModel.accessToken}';

          final response = await dio.fetch(options);
          return handler.resolve(response);
        } else {
          // No refresh token available, clear tokens and reject
          await localDataSource.clearTokens();
          return handler.reject(err);
        }
      } catch (e) {
        // Token refresh failed, clear tokens and reject
        await localDataSource.clearTokens();
        return handler.reject(err);
      }
    }

    // For other errors, just pass through
    return handler.reject(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }
}
