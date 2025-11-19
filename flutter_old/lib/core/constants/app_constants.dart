class AppConstants {
  AppConstants._();

  // Storage
  static const String videoStoragePath = '/storage/emulated/0/AdPlayer/videos/';
  static const String appName = 'AdPlayer';

  // Video formats
  static const List<String> supportedVideoFormats = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
    '.3gp',
  ];

  // Token
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiresInKey = 'token_expires_in';
  static const String tokenSavedAtKey = 'token_saved_at';
  static const String deviceIdKey = 'device_id';
  static const String isLoggedInKey = 'is_logged_in';

  // Device Settings
  static const String brightnessKey = 'brightness';
  static const String volumeKey = 'volume';

  // Permissions
  static const String permissionsGrantedKey = 'permissions_granted';

  // Token refresh buffer (refresh 5 minutes before expiry)
  static const int tokenRefreshBuffer = 300; // 5 minutes in seconds

  // Database
  static const String databaseName = 'ad_player_db';
}
