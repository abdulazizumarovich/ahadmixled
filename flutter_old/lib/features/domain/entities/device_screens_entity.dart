import 'package:equatable/equatable.dart';
import 'package:tv_monitor/features/domain/entities/screen_config_entity.dart';

class DeviceScreensEntity extends Equatable {
  final String snNumber;
  final ScreenConfigEntity? frontScreen;
  final ScreenConfigEntity? backScreen;
  final ScreenConfigEntity? rightScreen;
  final ScreenConfigEntity? leftScreen;

  const DeviceScreensEntity({
    required this.snNumber,
    this.frontScreen,
    this.backScreen,
    this.rightScreen,
    this.leftScreen,
  });

  DeviceScreensEntity copyWith({
    String? snNumber,
    ScreenConfigEntity? frontScreen,
    ScreenConfigEntity? backScreen,
    ScreenConfigEntity? rightScreen,
    ScreenConfigEntity? leftScreen,
  }) {
    return DeviceScreensEntity(
      snNumber: snNumber ?? this.snNumber,
      frontScreen: frontScreen ?? this.frontScreen,
      backScreen: backScreen ?? this.backScreen,
      rightScreen: rightScreen ?? this.rightScreen,
      leftScreen: leftScreen ?? this.leftScreen,
    );
  }

  @override
  List<Object?> get props => [snNumber, frontScreen, backScreen, rightScreen, leftScreen];
}
