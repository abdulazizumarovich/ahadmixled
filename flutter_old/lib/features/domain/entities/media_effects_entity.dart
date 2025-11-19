import 'package:equatable/equatable.dart';

class MediaEffectsEntity extends Equatable {
  final String transition;
  final int fadeDuration;

  const MediaEffectsEntity({
    required this.transition,
    required this.fadeDuration,
  });

  @override
  List<Object?> get props => [transition, fadeDuration];
}
