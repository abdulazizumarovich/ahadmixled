class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;

  AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

class PermissionException implements Exception {
  final String message;

  PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}

class VideoDownloadException implements Exception {
  final String message;
  final String? videoId;

  VideoDownloadException({
    required this.message,
    this.videoId,
  });

  @override
  String toString() => 'VideoDownloadException: $message (Video ID: $videoId)';
}

class WebSocketException implements Exception {
  final String message;

  WebSocketException({required this.message});

  @override
  String toString() => 'WebSocketException: $message';
}
