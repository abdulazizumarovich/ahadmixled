import 'package:equatable/equatable.dart';

enum WebSocketAction {
  play,
  pause,
  next,
  previous,
  reloadPlaylist,
  switchPlaylist,
  playMedia, // Play specific media from specific playlist
  showTextOverlay,
  hideTextOverlay,
  setBrightness,
  setVolume,
  unknown,
}

enum TextOverlayPosition {
  top,
  bottom,
  left,
  right,
}

enum TextOverlayAnimation {
  scroll,
  static,
}

class TextOverlayConfig extends Equatable {
  final String text;
  final TextOverlayPosition position;
  final TextOverlayAnimation animation;
  final double speed; // pixels per second for scroll animation
  final int? fontSize;
  final String? backgroundColor;
  final String? textColor;

  const TextOverlayConfig({
    required this.text,
    required this.position,
    this.animation = TextOverlayAnimation.scroll,
    this.speed = 50.0,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
  });

  @override
  List<Object?> get props => [
        text,
        position,
        animation,
        speed,
        fontSize,
        backgroundColor,
        textColor,
      ];
}

class WebSocketMessageEntity extends Equatable {
  final WebSocketAction action;
  final int? playlistId;
  final int? mediaId; // For playMedia action
  final int? mediaIndex; // For playMedia action (alternative to mediaId)
  final TextOverlayConfig? textOverlayConfig;
  final int? brightness;
  final int? volume;

  const WebSocketMessageEntity({
    required this.action,
    this.playlistId,
    this.mediaId,
    this.mediaIndex,
    this.textOverlayConfig,
    this.brightness,
    this.volume,
  });

  @override
  List<Object?> get props => [
        action,
        playlistId,
        mediaId,
        mediaIndex,
        textOverlayConfig,
        brightness,
        volume,
      ];
}
