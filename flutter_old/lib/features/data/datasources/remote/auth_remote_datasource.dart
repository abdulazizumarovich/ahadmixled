import 'package:dio/dio.dart';
import 'package:tv_monitor/core/constants/api_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String username, required String password});

  Future<AuthModel> refreshToken({required String refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthModel> login({required String username, required String password}) async {
    try {
      AppLogger.authInfo('Attempting login for user: $username');

      final response = await dio.post(ApiConstants.login, data: {'username': username, 'password': password});

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.authInfo('Login successful for user: $username');
        return AuthModel.fromJson(response.data as DataMap);
      } else {
        AppLogger.authError('Login failed with status: ${response.statusCode}');
        throw ServerException(message: response.data['message'] ?? 'Login failed', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      AppLogger.authError('Login network error', e);
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.authError('Login unexpected error', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<AuthModel> refreshToken({required String refreshToken}) async {
    try {
      AppLogger.authInfo('Attempting to refresh token');
      print({'refresh': refreshToken});
      final response = await dio.post(ApiConstants.refreshToken, data: {'refresh': refreshToken});

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.authInfo('Token refresh successful');
        return AuthModel.fromJson(response.data as DataMap);
      } else {
        AppLogger.authError('Token refresh failed with status: ${response.statusCode}');
        throw ServerException(
          message: response.data['message'] ?? 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.authError('Token refresh network error', e);
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.authError('Token refresh unexpected error', e);
      throw ServerException(message: e.toString());
    }
  }
}
