import 'package:equatable/equatable.dart';

class MediaLayoutEntity extends Equatable {
  final int x;
  final int y;
  final int width;
  final int height;
  final int zIndex;

  const MediaLayoutEntity({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.zIndex,
  });

  @override
  List<Object?> get props => [x, y, width, height, zIndex];
}
