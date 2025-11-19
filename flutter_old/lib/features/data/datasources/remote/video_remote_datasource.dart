import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tv_monitor/core/constants/api_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/models/device_screens_model.dart';

abstract class VideoRemoteDataSource {
  Future<DeviceScreensModel> getDeviceScreens({required String deviceId});

  Future<String> downloadMedia({required String url, required String savePath, Function(int, int)? onProgress});

  Future<void> uploadScreenshot({required String deviceId, required int mediaId, required File imageFile});
}

class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  final Dio dio;

  VideoRemoteDataSourceImpl({required this.dio});

  @override
  Future<DeviceScreensModel> getDeviceScreens({required String deviceId}) async {
    try {
      AppLogger.videoInfo('Fetching device screens for device: $deviceId');

      final response = await dio.get(ApiConstants.playlist(deviceId));
      if (response.statusCode == 200) {
        final deviceScreens = DeviceScreensModel.fromJson(response.data as DataMap);
        AppLogger.videoInfo('Device screens fetched successfully');
        return deviceScreens;
      } else {
        AppLogger.videoError('Failed to fetch device screens - status: ${response.statusCode}');
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch device screens',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.videoError('Device screens fetch network error', e);
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.videoError('Device screens fetch unexpected error', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> downloadMedia({required String url, required String savePath, Function(int, int)? onProgress}) async {
    try {
      AppLogger.videoInfo('Starting media download from: $url');

      int lastLoggedProgress = -1;
      int lastReceived = 0;
      DateTime lastProgressTime = DateTime.now();

      await dio.download(
        url,
        savePath,
        options: Options(
          receiveTimeout: const Duration(minutes: 5), // 5 minute timeout per chunk
          sendTimeout: const Duration(minutes: 2),
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = ((received / total) * 100).round();
            final now = DateTime.now();
            final timeSinceLastProgress = now.difference(lastProgressTime).inSeconds;

            // Detect stalled download: same received bytes for > 30 seconds
            if (received == lastReceived && timeSinceLastProgress > 30) {
              AppLogger.videoError(
                'Download stalled',
                'No progress for $timeSinceLastProgress seconds at $progress% ($received/$total bytes)',
              );
              throw VideoDownloadException(message: 'Download stalled - no progress for $timeSinceLastProgress seconds');
            }

            // Only log progress every 10% to avoid spam
            if (progress != lastLoggedProgress && (progress % 10 == 0 || progress == 100)) {
              AppLogger.videoInfo('Download progress: $progress% ($received/$total bytes)');
              lastLoggedProgress = progress;
            }

            // Update progress tracking
            if (received != lastReceived) {
              lastReceived = received;
              lastProgressTime = now;
            }

            onProgress?.call(received, total);
          }
        },
      );

      // Verify file was actually downloaded
      final file = File(savePath);
      if (!await file.exists()) {
        throw VideoDownloadException(message: 'Download completed but file not found at $savePath');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        await file.delete();
        throw VideoDownloadException(message: 'Downloaded file is empty');
      }

      AppLogger.videoInfo('Media download completed: $savePath (size: $fileSize bytes)');
      return savePath;
    } on DioException catch (e) {
      // Clean up partial download
      try {
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
          AppLogger.videoInfo('Cleaned up partial download: $savePath');
        }
      } catch (cleanupError) {
        AppLogger.videoInfo('Could not clean up partial download: $cleanupError');
      }

      final errorMessage = e.type == DioExceptionType.receiveTimeout
          ? 'Download timeout - network too slow or unstable'
          : e.message ?? 'Failed to download media';
      throw VideoDownloadException(message: errorMessage);
    } catch (e) {
      // Clean up on any error
      try {
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      if (e is VideoDownloadException) rethrow;
      throw VideoDownloadException(message: e.toString());
    }
  }

  @override
  Future<void> uploadScreenshot({required String deviceId, required int mediaId, required File imageFile}) async {
    try {
      final formData = FormData.fromMap({
        'device_id': deviceId,
        'media_id': mediaId,
        'image_file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'screenshot_${mediaId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await dio.post(ApiConstants.screenshot, data: formData);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to upload screenshot',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
