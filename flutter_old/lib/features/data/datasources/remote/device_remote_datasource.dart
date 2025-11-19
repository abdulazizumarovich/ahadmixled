import 'package:dio/dio.dart';
import 'package:tv_monitor/core/constants/api_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/models/device_model.dart';

abstract class DeviceRemoteDataSource {
  Future<String> registerDevice({required DeviceModel deviceInfo});
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final Dio dio;

  DeviceRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> registerDevice({required DeviceModel deviceInfo}) async {
    try {
      AppLogger.deviceInfo('Registering device: ${deviceInfo.snNumber}');
      AppLogger.deviceInfo('Device details - Brand: ${deviceInfo.brand}, Model: ${deviceInfo.model}');

      final response = await dio.post(ApiConstants.deviceRegister, data: deviceInfo.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as DataMap;
        final snNumber = data['data']['sn_number'] as String;
        AppLogger.deviceInfo('Device registered successfully with SN: $snNumber');
        return snNumber;
      } else {
        AppLogger.deviceError('Device registration failed with status: ${response.statusCode}');
        throw ServerException(
          message: response.data['message'] ?? 'Device registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.deviceError('Device registration network error', e);
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.deviceError('Device registration unexpected error', e);
      throw ServerException(message: e.toString());
    }
  }
}
