import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_monitor/core/constants/app_constants.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<int?> getTokenExpiresIn();

  Future<int?> getTokenSavedAt();

  Future<void> clearTokens();

  Future<bool> isTokenExpired();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      await Future.wait([
        sharedPreferences.setString(AppConstants.accessTokenKey, accessToken),
        sharedPreferences.setString(AppConstants.refreshTokenKey, refreshToken),
        sharedPreferences.setInt(AppConstants.tokenExpiresInKey, expiresIn),
        sharedPreferences.setInt(
          AppConstants.tokenSavedAtKey,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        sharedPreferences.setBool(AppConstants.isLoggedInKey, true),
      ]);
    } catch (e) {
      throw CacheException(message: 'Failed to save tokens: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return sharedPreferences.getString(AppConstants.accessTokenKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get access token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return sharedPreferences.getString(AppConstants.refreshTokenKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get refresh token: ${e.toString()}');
    }
  }

  @override
  Future<int?> getTokenExpiresIn() async {
    try {
      return sharedPreferences.getInt(AppConstants.tokenExpiresInKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get token expires in: ${e.toString()}');
    }
  }

  @override
  Future<int?> getTokenSavedAt() async {
    try {
      return sharedPreferences.getInt(AppConstants.tokenSavedAtKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get token saved at: ${e.toString()}');
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        sharedPreferences.remove(AppConstants.accessTokenKey),
        sharedPreferences.remove(AppConstants.refreshTokenKey),
        sharedPreferences.remove(AppConstants.tokenExpiresInKey),
        sharedPreferences.remove(AppConstants.tokenSavedAtKey),
        sharedPreferences.setBool(AppConstants.isLoggedInKey, false),
      ]);
    } catch (e) {
      throw CacheException(message: 'Failed to clear tokens: ${e.toString()}');
    }
  }

  @override
  Future<bool> isTokenExpired() async {
    try {
      final expiresIn = await getTokenExpiresIn();
      final savedAt = await getTokenSavedAt();

      if (expiresIn == null || savedAt == null) {
        return true;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiresAt = savedAt + expiresIn - AppConstants.tokenRefreshBuffer;

      return now >= expiresAt;
    } catch (e) {
      return true;
    }
  }
}
