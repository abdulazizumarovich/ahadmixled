import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/models/screen_config_model.dart';
import 'package:tv_monitor/features/domain/entities/device_screens_entity.dart';

class DeviceScreensModel {
  final String snNumber;
  final ScreenConfigModel? frontScreen;
  final ScreenConfigModel? backScreen;
  final ScreenConfigModel? rightScreen;
  final ScreenConfigModel? leftScreen;

  DeviceScreensModel({required this.snNumber, this.frontScreen, this.backScreen, this.rightScreen, this.leftScreen});

  factory DeviceScreensModel.fromJson(DataMap json) {
    return DeviceScreensModel(
      snNumber: json['sn_number'] as String,
      frontScreen: json['front_screen'] != null ? ScreenConfigModel.fromJson(json['front_screen'] as DataMap) : null,
      backScreen: json['back_screen'] != null ? ScreenConfigModel.fromJson(json['back_screen'] as DataMap) : null,
      rightScreen: json['right_screen'] != null ? ScreenConfigModel.fromJson(json['right_screen'] as DataMap) : null,
      leftScreen: json['left_screen'] != null ? ScreenConfigModel.fromJson(json['left_screen'] as DataMap) : null,
    );
  }

  DataMap toJson() {
    return {
      'sn_number': snNumber,
      if (frontScreen != null) 'front_screen': frontScreen!.toJson(),
      if (backScreen != null) 'back_screen': backScreen!.toJson(),
      if (rightScreen != null) 'right_screen': rightScreen!.toJson(),
      if (leftScreen != null) 'left_screen': leftScreen!.toJson(),
    };
  }

  DeviceScreensEntity toEntity() {
    return DeviceScreensEntity(
      snNumber: snNumber,
      frontScreen: frontScreen?.toEntity(),
      backScreen: backScreen?.toEntity(),
      rightScreen: rightScreen?.toEntity(),
      leftScreen: leftScreen?.toEntity(),
    );
  }

  factory DeviceScreensModel.fromEntity(DeviceScreensEntity entity) {
    return DeviceScreensModel(
      snNumber: entity.snNumber,
      frontScreen: entity.frontScreen != null ? ScreenConfigModel.fromEntity(entity.frontScreen!) : null,
      backScreen: entity.backScreen != null ? ScreenConfigModel.fromEntity(entity.backScreen!) : null,
      rightScreen: entity.rightScreen != null ? ScreenConfigModel.fromEntity(entity.rightScreen!) : null,
      leftScreen: entity.leftScreen != null ? ScreenConfigModel.fromEntity(entity.leftScreen!) : null,
    );
  }
}
