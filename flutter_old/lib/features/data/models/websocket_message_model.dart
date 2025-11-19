import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';

class WebSocketMessageModel extends WebSocketMessageEntity {
  const WebSocketMessageModel({
    required super.action,
    super.playlistId,
    super.mediaId,
    super.mediaIndex,
    super.textOverlayConfig,
    super.brightness,
    super.volume,
  });

  factory WebSocketMessageModel.fromJson(DataMap json) {
    final actionStr = json['action'] as String?;
    WebSocketAction action;

    switch (actionStr) {
      case 'play':
        action = WebSocketAction.play;
        break;
      case 'pause':
        action = WebSocketAction.pause;
        break;
      case 'next':
        action = WebSocketAction.next;
        break;
      case 'previous':
        action = WebSocketAction.previous;
        break;
      case 'reload_playlist':
        action = WebSocketAction.reloadPlaylist;
        break;
      case 'switch_playlist':
        action = WebSocketAction.switchPlaylist;
        break;
      case 'play_media':
        action = WebSocketAction.playMedia;
        break;
      case 'show_text_overlay':
        action = WebSocketAction.showTextOverlay;
        break;
      case 'hide_text_overlay':
        action = WebSocketAction.hideTextOverlay;
        break;
      case 'set_brightness':
        action = WebSocketAction.setBrightness;
        break;
      case 'set_volume':
        action = WebSocketAction.setVolume;
        break;
      default:
        action = WebSocketAction.unknown;
    }

    // Parse text overlay config if present
    TextOverlayConfig? textOverlayConfig;
    if (json['text_overlay'] != null) {
      final overlayData = json['text_overlay'] as DataMap;
      textOverlayConfig = _parseTextOverlayConfig(overlayData);
    }

    // Parse brightness, volume, playlistId, mediaId, and mediaIndex if present
    final brightness = json['brightness'] as int?;
    final volume = json['volume'] as int?;
    final playlistId = json['playlist_id'] as int?;
    final mediaId = json['media_id'] as int?;
    final mediaIndex = json['media_index'] as int?;

    return WebSocketMessageModel(
      action: action,
      playlistId: playlistId,
      mediaId: mediaId,
      mediaIndex: mediaIndex,
      textOverlayConfig: textOverlayConfig,
      brightness: brightness,
      volume: volume,
    );
  }

  static TextOverlayConfig _parseTextOverlayConfig(DataMap json) {
    final text = json['text'] as String? ?? '';

    // Parse position
    TextOverlayPosition position = TextOverlayPosition.bottom;
    final positionStr = json['position'] as String?;
    switch (positionStr) {
      case 'top':
        position = TextOverlayPosition.top;
        break;
      case 'bottom':
        position = TextOverlayPosition.bottom;
        break;
      case 'left':
        position = TextOverlayPosition.left;
        break;
      case 'right':
        position = TextOverlayPosition.right;
        break;
    }

    // Parse animation
    TextOverlayAnimation animation = TextOverlayAnimation.scroll;
    final animationStr = json['animation'] as String?;
    if (animationStr == 'static') {
      animation = TextOverlayAnimation.static;
    }

    final speed = (json['speed'] as num?)?.toDouble() ?? 50.0;
    final fontSize = json['font_size'] as int?;
    final backgroundColor = json['background_color'] as String?;
    final textColor = json['text_color'] as String?;

    return TextOverlayConfig(
      text: text,
      position: position,
      animation: animation,
      speed: speed,
      fontSize: fontSize,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  DataMap toJson() {
    String actionStr;
    switch (action) {
      case WebSocketAction.play:
        actionStr = 'play';
        break;
      case WebSocketAction.pause:
        actionStr = 'pause';
        break;
      case WebSocketAction.next:
        actionStr = 'next';
        break;
      case WebSocketAction.previous:
        actionStr = 'previous';
        break;
      case WebSocketAction.reloadPlaylist:
        actionStr = 'reload_playlist';
        break;
      case WebSocketAction.switchPlaylist:
        actionStr = 'switch_playlist';
        break;
      case WebSocketAction.playMedia:
        actionStr = 'play_media';
        break;
      case WebSocketAction.showTextOverlay:
        actionStr = 'show_text_overlay';
        break;
      case WebSocketAction.hideTextOverlay:
        actionStr = 'hide_text_overlay';
        break;
      case WebSocketAction.setBrightness:
        actionStr = 'set_brightness';
        break;
      case WebSocketAction.setVolume:
        actionStr = 'set_volume';
        break;
      case WebSocketAction.unknown:
        actionStr = 'unknown';
    }

    final json = <String, dynamic>{'action': actionStr};

    if (playlistId != null) {
      json['playlist_id'] = playlistId;
    }

    if (mediaId != null) {
      json['media_id'] = mediaId;
    }

    if (mediaIndex != null) {
      json['media_index'] = mediaIndex;
    }

    if (textOverlayConfig != null) {
      json['text_overlay'] = _textOverlayConfigToJson(textOverlayConfig!);
    }

    if (brightness != null) {
      json['brightness'] = brightness;
    }

    if (volume != null) {
      json['volume'] = volume;
    }

    return json;
  }

  static DataMap _textOverlayConfigToJson(TextOverlayConfig config) {
    String positionStr;
    switch (config.position) {
      case TextOverlayPosition.top:
        positionStr = 'top';
        break;
      case TextOverlayPosition.bottom:
        positionStr = 'bottom';
        break;
      case TextOverlayPosition.left:
        positionStr = 'left';
        break;
      case TextOverlayPosition.right:
        positionStr = 'right';
        break;
    }

    final animationStr = config.animation == TextOverlayAnimation.scroll ? 'scroll' : 'static';

    final json = <String, dynamic>{
      'text': config.text,
      'position': positionStr,
      'animation': animationStr,
      'speed': config.speed,
    };

    if (config.fontSize != null) json['font_size'] = config.fontSize;
    if (config.backgroundColor != null) {
      json['background_color'] = config.backgroundColor;
    }
    if (config.textColor != null) json['text_color'] = config.textColor;

    return json;
  }

  WebSocketMessageEntity toEntity() {
    return WebSocketMessageEntity(
      action: action,
      playlistId: playlistId,
      mediaId: mediaId,
      mediaIndex: mediaIndex,
      textOverlayConfig: textOverlayConfig,
      brightness: brightness,
      volume: volume,
    );
  }
}
