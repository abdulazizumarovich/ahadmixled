# CRITICAL DEBUG LOGGING SETUP

## O'RNATISH:

### 1. video_bloc.dart ga qo'shing:

File boshida import qo'shing:
```dart
import 'package:tv_monitor/core/utils/download_debug_logger.dart';
```

### 2. _onSelectPlaylist metodida (line ~367 atrofida):

```dart
} else {
  // Different playlist - switch and start playing immediately
  emit(currentState.copyWith(
    currentPlaylist: selectedPlaylist,
    currentMediaIndex: 0,
    isPlaying: true,
  ));

  // ADD THIS:
  DownloadDebugLogger.logStateEmit(
    eventName: 'SelectPlaylist',
    isWebSocketReload: false,
    playlistName: selectedPlaylist.name,
    playlistId: selectedPlaylist.id,
  );
}
```

### 3. _onLoadDeviceScreens metodida (line ~175 atrofida):

```dart
emit(VideoLoaded(
  deviceScreens: deviceScreens,
  playlists: playlists,
  currentPlaylist: currentPlaylist,
  currentMediaIndex: mediaIndex,
  isPlaying: wasPlaying,
  textOverlayConfig: textOverlayConfig,
  brightness: brightness,
  volume: volume,
  isWebSocketReload: true,
));

// ADD THIS:
DownloadDebugLogger.logStateEmit(
  eventName: 'LoadDeviceScreens',
  isWebSocketReload: true,
  playlistName: currentPlaylist?.name,
  playlistId: currentPlaylist?.id,
);
```

### 4. home_screen.dart ga qo'shing:

File boshida import:
```dart
import 'package:tv_monitor/core/utils/download_debug_logger.dart';
```

Listener ichida (line ~147 atrofida):
```dart
if (videoState.isWebSocketReload) {
  // ADD THIS:
  DownloadDebugLogger.logHomeScreenReceive(
    isWebSocketReload: true,
    playlistName: videoState.currentPlaylist?.name,
    willTriggerDownload: true,
  );

  AppLogger.info('🔄 [APP] WebSocket reload detected via flag - checking for downloads');
  _handleWebSocketReload(videoState);
} else {
  // ADD THIS:
  DownloadDebugLogger.logHomeScreenReceive(
    isWebSocketReload: false,
    playlistName: videoState.currentPlaylist?.name,
    willTriggerDownload: false,
  );

  AppLogger.info('🔄 [APP] Local state change - NO download check');
}
```

### 5. _autoDownloadPlaylistsOnReload metodida (line ~345 atrofida):

```dart
AppLogger.info('📥 [APP] WebSocket reload: Starting background download for ${playlistsToDownload.length} playlists');

// ADD THIS for each playlist:
for (final playlist in playlistsToDownload) {
  DownloadDebugLogger.logDownloadStart(
    playlistName: playlist.name,
    playlistId: playlist.id,
    reason: 'WebSocket reload - playlist needs update',
  );
}

_downloadService.enqueueMultiple(playlistsToDownload);
```

### 6. websocket_bloc.dart ga qo'shing (optional):

File boshida import:
```dart
import 'package:tv_monitor/core/utils/download_debug_logger.dart';
```

switchPlaylist case'da (line ~127 atrofida):
```dart
case WebSocketAction.switchPlaylist:
  if (message.playlistId != null) {
    // ADD THIS:
    final currentState = videoBloc.state as VideoLoaded;
    DownloadDebugLogger.logSwitchCommand(
      fromPlaylistId: currentState.currentPlaylist?.id ?? 0,
      toPlaylistId: message.playlistId!,
    );

    AppLogger.websocketInfo('🔀 Dispatching SelectPlaylist event with ID: ${message.playlistId}');
    videoBloc.add(SelectPlaylist(playlistId: message.playlistId!));
  }
```

## ISHLATISH:

1. Ilovani ishga tushiring
2. Switch playlist qiling bir necha marta
3. Console'da quyidagi loglarni ko'ring:

```
╔═══════════════════════════════════════════════════════════════════════════
║ [📤 VIDEO_BLOC_EMIT] Event: SelectPlaylist
║ Playlist: My Playlist (ID: 123)
║ isWebSocketReload: ✅ FALSE (NO DOWNLOAD)
╚═══════════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════════
║ [✅ HOME_SCREEN_LISTENER] State received
║ Playlist: My Playlist
║ isWebSocketReload: false
║ Action: NO DOWNLOAD CHECK
╚═══════════════════════════════════════════════════════════════════════════
```

## AGAR DOWNLOAD KETSA:

Quyidagi log ko'rinadi:
```
╔═══════════════════════════════════════════════════════════════════════════
║ [🚨🚨🚨 DOWNLOAD_STARTED] THIS SHOULD ONLY HAPPEN ON WEBSOCKET RELOAD!
║ Playlist: My Playlist (ID: 123)
║ Reason: ...
╚═══════════════════════════════════════════════════════════════════════════
```

Bu holda loglarni to'liq ko'rsating va men aniq sababni topaman!

## LOGGING DISABLE QILISH:

Debug tugagach, file boshida:
```dart
void main() {
  DownloadDebugLogger.disable();  // Add this
  runApp(MyApp());
}
```
