part of 'video_bloc.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeviceScreens extends VideoEvent {
  final String deviceId;

  const LoadDeviceScreens({required this.deviceId});

  @override
  List<Object?> get props => [deviceId];
}

class DownloadPlaylist extends VideoEvent {
  final PlaylistEntity playlist;

  const DownloadPlaylist({required this.playlist});

  @override
  List<Object?> get props => [playlist];
}

class LoadLocalPlaylists extends VideoEvent {
  const LoadLocalPlaylists();
}

class SelectPlaylist extends VideoEvent {
  final int playlistId;

  const SelectPlaylist({required this.playlistId});

  @override
  List<Object?> get props => [playlistId];
}

class DeletePlaylistEvent extends VideoEvent {
  final int playlistId;

  const DeletePlaylistEvent({required this.playlistId});

  @override
  List<Object?> get props => [playlistId];
}

class PlayVideo extends VideoEvent {
  final int index;

  const PlayVideo({required this.index});

  @override
  List<Object?> get props => [index];
}

class PauseVideo extends VideoEvent {
  const PauseVideo();
}

class PlayNextVideo extends VideoEvent {
  const PlayNextVideo();
}

class PlayPreviousVideo extends VideoEvent {
  const PlayPreviousVideo();
}

class CaptureAndUploadScreenshot extends VideoEvent {
  final String deviceId;
  final int mediaId;
  final List<int> imageBytes;

  const CaptureAndUploadScreenshot({
    required this.deviceId,
    required this.mediaId,
    required this.imageBytes,
  });

  @override
  List<Object?> get props => [deviceId, mediaId, imageBytes];
}

class ShowTextOverlay extends VideoEvent {
  final TextOverlayConfig config;

  const ShowTextOverlay({required this.config});

  @override
  List<Object?> get props => [config];
}

class HideTextOverlay extends VideoEvent {
  const HideTextOverlay();
}

class SetBrightness extends VideoEvent {
  final int brightness;

  const SetBrightness({required this.brightness});

  @override
  List<Object?> get props => [brightness];
}

class SetVolume extends VideoEvent {
  final int volume;

  const SetVolume({required this.volume});

  @override
  List<Object?> get props => [volume];
}

class RedownloadMediaItem extends VideoEvent {
  final int mediaIndex;

  const RedownloadMediaItem({required this.mediaIndex});

  @override
  List<Object?> get props => [mediaIndex];
}
