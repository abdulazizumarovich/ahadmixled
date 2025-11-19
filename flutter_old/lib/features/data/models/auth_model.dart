import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({required super.accessToken, required super.refreshToken, required super.expiresIn});

  factory AuthModel.fromJson(DataMap json) {
    return AuthModel(
      accessToken: json['access'] ?? '',
      refreshToken: json['refresh'] ?? '',
      expiresIn: json['expires_in'] ?? 1,
    );
  }

  DataMap toJson() {
    return {'access': accessToken, 'refresh': refreshToken, 'expires_in': expiresIn};
  }

  AuthEntity toEntity() {
    return AuthEntity(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn);
  }
}
