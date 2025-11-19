class ApiConstants {
  ApiConstants._();

  // Base URL - Update this with your actual backend URL
  // production
  static const domainName = 'admin-led.ohayo.uz';
  // local
  // static const domainName = '3aba3e6417e4.ngrok-free.app';
  static const String domain = 'https://$domainName';
  static const String baseUrl = '$domain/api/v1';

  // WebSocket URL (use wss:// for secure connection with ngrok HTTPS)
  static String wsUrl(String deviceId, String token) {
    print('wss://$domainName/ws/cloud/tb_device/?token=$token&sn_number=$deviceId');
    return 'wss://$domainName/ws/cloud/tb_device/?token=$token&sn_number=$deviceId';
  }

  // Auth Endpoints
  static const String login = '/auth/token/';
  static const String refreshToken = '/auth/token/refresh/';

  // Device Endpoints
  static const String deviceRegister = '/admin/cloud/device/register/';

  // Video Endpoints
  static String playlist(String deviceId) => '/admin/cloud/playlists?sn_number=$deviceId';
  static const String screenshot = '/screenshot';

  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static String bearerToken(String token) => 'Bearer $token';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
