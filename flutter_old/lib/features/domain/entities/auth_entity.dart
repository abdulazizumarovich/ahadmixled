import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}
