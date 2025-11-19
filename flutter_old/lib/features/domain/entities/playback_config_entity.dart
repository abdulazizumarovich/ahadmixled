import 'package:equatable/equatable.dart';

class PlaybackConfigEntity extends Equatable {
  final bool repeat;
  final int repeatCount;
  final String backgroundColor;

  const PlaybackConfigEntity({
    required this.repeat,
    required this.repeatCount,
    required this.backgroundColor,
  });

  @override
  List<Object?> get props => [repeat, repeatCount, backgroundColor];
}
