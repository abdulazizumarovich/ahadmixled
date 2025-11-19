import 'dart:developer' as developer;

/// CRITICAL DEBUG LOGGER - Faqat download trigger'larni kuzatish uchun
class DownloadDebugLogger {
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  /// Log VideoLoaded state emit
  static void logStateEmit({
    required String eventName,
    required bool isWebSocketReload,
    required String? playlistName,
    required int? playlistId,
  }) {
    if (!_enabled) return;

    final reloadFlag = isWebSocketReload ? '🚨 TRUE (WILL TRIGGER DOWNLOAD!)' : '✅ FALSE (NO DOWNLOAD)';

    print('\n');
    print('╔═══════════════════════════════════════════════════════════════════════════');
    print('║ [📤 VIDEO_BLOC_EMIT] Event: $eventName');
    print('║ Playlist: ${playlistName ?? "null"} (ID: ${playlistId ?? "null"})');
    print('║ isWebSocketReload: $reloadFlag');
    print('╚═══════════════════════════════════════════════════════════════════════════');
    print('\n');

    // Also log to developer console for filtering
    developer.log(
      'VideoBloc EMIT | $eventName | isWebSocketReload: $isWebSocketReload | Playlist: $playlistName',
      name: 'DOWNLOAD_TRIGGER',
    );
  }

  /// Log when HomeScreen receives VideoLoaded state
  static void logHomeScreenReceive({
    required bool isWebSocketReload,
    required String? playlistName,
    required bool willTriggerDownload,
  }) {
    if (!_enabled) return;

    final icon = willTriggerDownload ? '🚨' : '✅';
    final action = willTriggerDownload ? 'CHECKING FOR DOWNLOADS' : 'NO DOWNLOAD CHECK';

    print('\n');
    print('╔═══════════════════════════════════════════════════════════════════════════');
    print('║ [$icon HOME_SCREEN_LISTENER] State received');
    print('║ Playlist: ${playlistName ?? "null"}');
    print('║ isWebSocketReload: $isWebSocketReload');
    print('║ Action: $action');
    print('╚═══════════════════════════════════════════════════════════════════════════');
    print('\n');

    // Also log to developer console
    developer.log(
      'HomeScreen RECEIVE | isWebSocketReload: $isWebSocketReload | Will download: $willTriggerDownload',
      name: 'DOWNLOAD_TRIGGER',
    );
  }

  /// Log when download actually starts
  static void logDownloadStart({
    required String playlistName,
    required int playlistId,
    required String reason,
  }) {
    if (!_enabled) return;

    print('\n');
    print('╔═══════════════════════════════════════════════════════════════════════════');
    print('║ [🚨🚨🚨 DOWNLOAD_STARTED] THIS SHOULD ONLY HAPPEN ON WEBSOCKET RELOAD!');
    print('║ Playlist: $playlistName (ID: $playlistId)');
    print('║ Reason: $reason');
    print('╚═══════════════════════════════════════════════════════════════════════════');
    print('\n');

    developer.log(
      'DOWNLOAD STARTED | $playlistName | Reason: $reason',
      name: 'DOWNLOAD_TRIGGER',
      level: 1000, // High severity
    );
  }

  /// Log switch_playlist WebSocket command
  static void logSwitchCommand({
    required int fromPlaylistId,
    required int toPlaylistId,
  }) {
    if (!_enabled) return;

    print('\n');
    print('╔═══════════════════════════════════════════════════════════════════════════');
    print('║ [🔀 WEBSOCKET_COMMAND] switch_playlist');
    print('║ From Playlist ID: $fromPlaylistId');
    print('║ To Playlist ID: $toPlaylistId');
    print('║ Expected: SelectPlaylist event with isWebSocketReload=FALSE');
    print('╚═══════════════════════════════════════════════════════════════════════════');
    print('\n');
  }
}
