import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required String message,
    this.statusCode,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({required String message}) : super(message: message);
}

class AuthFailure extends Failure {
  const AuthFailure({required String message}) : super(message: message);
}

class PermissionFailure extends Failure {
  const PermissionFailure({required String message}) : super(message: message);
}

class VideoDownloadFailure extends Failure {
  final String? videoId;

  const VideoDownloadFailure({
    required String message,
    this.videoId,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, videoId];
}

class WebSocketFailure extends Failure {
  const WebSocketFailure({required String message}) : super(message: message);
}
