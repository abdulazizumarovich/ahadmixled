import 'package:equatable/equatable.dart';

class MediaTimingEntity extends Equatable {
  final int startTime;
  final int duration;
  final bool loop;

  const MediaTimingEntity({
    required this.startTime,
    required this.duration,
    required this.loop,
  });

  @override
  List<Object?> get props => [startTime, duration, loop];
}
