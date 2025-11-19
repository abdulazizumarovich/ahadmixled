part of 'video_bloc.dart';

abstract class VideoState extends Equatable {
  const VideoState();

  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {
  const VideoInitial();
}

class VideoLoading extends VideoState {
  const VideoLoading();
}

class VideoLoaded extends VideoState {
  final DeviceScreensEntity? deviceScreens;
  final List<PlaylistEntity> playlists;
  final PlaylistEntity? currentPlaylist;
  final int currentMediaIndex;
  final bool isPlaying;
  final TextOverlayConfig? textOverlayConfig;
  final int brightness;
  final int volume;

  // CRITICAL: Flag to indicate if this state is from WebSocket reload
  // Only trigger downloads when this is true
  final bool isWebSocketReload;

  const VideoLoaded({
    this.deviceScreens,
    required this.playlists,
    this.currentPlaylist,
    this.currentMediaIndex = 0,
    this.isPlaying = false,
    this.textOverlayConfig,
    this.brightness = 50,
    this.volume = 50,
    this.isWebSocketReload = false, // Default: NOT a WebSocket reload
  });

  VideoLoaded copyWith({
    DeviceScreensEntity? deviceScreens,
    List<PlaylistEntity>? playlists,
    PlaylistEntity? currentPlaylist,
    int? currentMediaIndex,
    bool? isPlaying,
    TextOverlayConfig? textOverlayConfig,
    bool clearTextOverlay = false,
    int? brightness,
    int? volume,
    bool? isWebSocketReload,
  }) {
    return VideoLoaded(
      deviceScreens: deviceScreens, // Don't preserve - always use new value or null
      playlists: playlists ?? this.playlists,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      currentMediaIndex: currentMediaIndex ?? this.currentMediaIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      textOverlayConfig: clearTextOverlay ? null : (textOverlayConfig ?? this.textOverlayConfig),
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      isWebSocketReload: isWebSocketReload ?? false, // Default: false (NOT a reload)
    );
  }

  @override
  List<Object?> get props => [
        deviceScreens,
        playlists,
        currentPlaylist,
        currentMediaIndex,
        isPlaying,
        textOverlayConfig,
        brightness,
        volume,
        isWebSocketReload,
      ];
}

class PlaylistDownloading extends VideoState {
  final PlaylistEntity playlist;
  final int downloadedItems;
  final int totalItems;
  final String? currentMediaName;

  const PlaylistDownloading({
    required this.playlist,
    required this.downloadedItems,
    required this.totalItems,
    this.currentMediaName,
  });

  double get progress {
    if (totalItems == 0) return 0;
    return downloadedItems / totalItems;
  }

  @override
  List<Object?> get props => [playlist, downloadedItems, totalItems, currentMediaName];
}

class VideoError extends VideoState {
  final String message;

  const VideoError({required this.message});

  @override
  List<Object?> get props => [message];
}

class MediaItemRedownloading extends VideoState {
  final int mediaIndex;
  final double progress;

  const MediaItemRedownloading({
    required this.mediaIndex,
    this.progress = 0.0,
  });

  @override
  List<Object?> get props => [mediaIndex, progress];
}
