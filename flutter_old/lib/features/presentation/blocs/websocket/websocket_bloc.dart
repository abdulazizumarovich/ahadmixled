import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';
import 'package:tv_monitor/features/domain/usecases/websocket/connect_websocket_usecase.dart';
import 'package:tv_monitor/features/domain/repositories/websocket_repository.dart';
import 'package:tv_monitor/features/presentation/blocs/video/video_bloc.dart';
import 'package:tv_monitor/features/data/datasources/local/device_local_datasource.dart';

part 'websocket_event.dart';
part 'websocket_state.dart';

class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final ConnectWebSocketUseCase connectWebSocketUseCase;
  final WebSocketRepository webSocketRepository;
  final VideoBloc videoBloc;
  final DeviceLocalDataSource deviceLocalDataSource;
  StreamSubscription? _messageSubscription;

  WebSocketBloc({
    required this.connectWebSocketUseCase,
    required this.webSocketRepository,
    required this.videoBloc,
    required this.deviceLocalDataSource,
  }) : super(const WebSocketInitial()) {
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<WebSocketMessageReceived>(_onWebSocketMessageReceived);
  }

  Future<void> _onConnectWebSocket(ConnectWebSocket event, Emitter<WebSocketState> emit) async {
    AppLogger.websocketInfo('🔌 Connecting to WebSocket...');
    emit(const WebSocketConnecting());

    final result = await connectWebSocketUseCase(
      ConnectWebSocketParams(deviceId: event.deviceId, accessToken: event.accessToken),
    );

    result.fold(
      (failure) {
        AppLogger.websocketError('❌ WebSocket connection failed: ${failure.message}');
        emit(WebSocketError(message: failure.message));
      },
      (_) {
        AppLogger.websocketInfo('✅ WebSocket connected successfully');
        emit(const WebSocketConnected());

        // Check if VideoBloc has playlists loaded
        if (videoBloc.state is! VideoLoaded) {
          AppLogger.websocketInfo('⚠️ VideoBloc not loaded, triggering local playlist load...');
          videoBloc.add(const LoadLocalPlaylists());
        } else {
          AppLogger.websocketInfo('✅ VideoBloc already loaded with playlists');
        }

        // Listen to incoming WebSocket messages from repository
        _messageSubscription = webSocketRepository.messages.listen(
          (message) {
            add(WebSocketMessageReceived(message: message));
          },
          onError: (error) {
            AppLogger.websocketError('❌ WebSocket stream error: $error');
            emit(WebSocketError(message: error.toString()));
          },
        );
      },
    );
  }

  Future<void> _onDisconnectWebSocket(DisconnectWebSocket event, Emitter<WebSocketState> emit) async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    emit(const WebSocketDisconnected());
  }

  Future<void> _onWebSocketMessageReceived(WebSocketMessageReceived event, Emitter<WebSocketState> emit) async {
    final message = event.message;

    AppLogger.websocketInfo('🎯 Processing WebSocket action: ${message.action}');

    // Check if VideoBloc is in VideoLoaded state for most actions
    final requiresVideoLoaded =
        message.action != WebSocketAction.setBrightness &&
        message.action != WebSocketAction.setVolume &&
        message.action != WebSocketAction.unknown;

    if (requiresVideoLoaded && videoBloc.state is! VideoLoaded) {
      AppLogger.websocketError(
        '⚠️ VideoBloc not ready (current state: ${videoBloc.state.runtimeType}). '
        'Skipping action: ${message.action}. Please wait for playlist to load.',
      );
      return;
    }

    // Handle WebSocket actions by dispatching events to VideoBloc
    switch (message.action) {
      case WebSocketAction.play:
        AppLogger.websocketInfo('▶️ Dispatching PlayVideo event');
        final currentState = videoBloc.state as VideoLoaded;
        videoBloc.add(PlayVideo(index: currentState.currentMediaIndex));
        break;
      case WebSocketAction.pause:
        AppLogger.websocketInfo('⏸️ Dispatching PauseVideo event');
        videoBloc.add(const PauseVideo());
        break;
      case WebSocketAction.next:
        AppLogger.websocketInfo('⏭️ Dispatching PlayNextVideo event');
        videoBloc.add(const PlayNextVideo());
        break;
      case WebSocketAction.previous:
        AppLogger.websocketInfo('⏮️ Dispatching PlayPreviousVideo event');
        videoBloc.add(const PlayPreviousVideo());
        break;
      case WebSocketAction.reloadPlaylist:
        AppLogger.websocketInfo('🔄 Dispatching ReloadPlaylists event');
        // Reload playlists from server
        final deviceId = await _getDeviceId();
        if (deviceId != null) {
          videoBloc.add(LoadDeviceScreens(deviceId: deviceId));
        } else {
          AppLogger.websocketError('❌ Cannot reload playlist: device ID not found');
        }
        break;
      case WebSocketAction.switchPlaylist:
        if (message.playlistId != null) {
          AppLogger.websocketInfo('🔀 Dispatching SelectPlaylist event with ID: ${message.playlistId}');
          videoBloc.add(SelectPlaylist(playlistId: message.playlistId!));
        } else {
          AppLogger.websocketError('❌ switchPlaylist action received but playlistId is null');
        }
        break;
      case WebSocketAction.playMedia:
        AppLogger.websocketInfo('🎯 Play specific media action received');
        if (message.playlistId == null) {
          AppLogger.websocketError('❌ playMedia action received but playlistId is null');
          break;
        }

        // First, switch to the specified playlist
        videoBloc.add(SelectPlaylist(playlistId: message.playlistId!));

        // Wait for playlist to be selected
        await Future.delayed(const Duration(milliseconds: 500));

        // Then find and play the specific media
        if (videoBloc.state is VideoLoaded) {
          final currentState = videoBloc.state as VideoLoaded;
          final playlist = currentState.currentPlaylist;

          if (playlist != null) {
            int? targetIndex;

            // Find media by ID if provided
            if (message.mediaId != null) {
              targetIndex = playlist.mediaItems.indexWhere((item) => item.mediaId == message.mediaId);
              if (targetIndex == -1) targetIndex = null;
            }

            // Or use direct index if provided
            if (targetIndex == null && message.mediaIndex != null) {
              if (message.mediaIndex! >= 0 && message.mediaIndex! < playlist.mediaItems.length) {
                targetIndex = message.mediaIndex;
              }
            }

            if (targetIndex != null) {
              AppLogger.websocketInfo('▶️ Playing media at index $targetIndex from playlist ${message.playlistId}');
              videoBloc.add(PlayVideo(index: targetIndex));
            } else {
              AppLogger.websocketError(
                '❌ Media not found: mediaId=${message.mediaId}, mediaIndex=${message.mediaIndex}',
              );
            }
          }
        }
        break;
      case WebSocketAction.showTextOverlay:
        if (message.textOverlayConfig != null) {
          AppLogger.websocketInfo('📝 Dispatching ShowTextOverlay event');
          videoBloc.add(ShowTextOverlay(config: message.textOverlayConfig!));
        } else {
          AppLogger.websocketError('❌ showTextOverlay action received but config is null');
        }
        break;
      case WebSocketAction.hideTextOverlay:
        AppLogger.websocketInfo('🚫 Dispatching HideTextOverlay event');
        videoBloc.add(const HideTextOverlay());
        break;
      case WebSocketAction.setBrightness:
        if (message.brightness != null) {
          AppLogger.websocketInfo('🔆 Dispatching SetBrightness event: ${message.brightness}');
          videoBloc.add(SetBrightness(brightness: message.brightness!));
        } else {
          AppLogger.websocketError('❌ setBrightness action received but brightness is null');
        }
        break;
      case WebSocketAction.setVolume:
        if (message.volume != null) {
          AppLogger.websocketInfo('🔊 Dispatching SetVolume event: ${message.volume}');
          videoBloc.add(SetVolume(volume: message.volume!));
        } else {
          AppLogger.websocketError('❌ setVolume action received but volume is null');
        }
        break;
      case WebSocketAction.unknown:
        AppLogger.websocketError('❓ Unknown WebSocket action received');
        break;
    }
  }

  Future<String?> _getDeviceId() async {
    try {
      return await deviceLocalDataSource.getSavedDeviceId();
    } catch (e) {
      AppLogger.websocketError('Failed to get device ID', e);
      return null;
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
