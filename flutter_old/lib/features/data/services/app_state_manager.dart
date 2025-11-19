import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';

/// App state persistence and recovery manager
/// Saves and restores app state for seamless recovery after network/power loss
class AppStateManager {
  static const String _keyCurrentPlaylistId = 'current_playlist_id';
  static const String _keyCurrentMediaIndex = 'current_media_index';
  static const String _keyIsPlaying = 'is_playing';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyPendingScreenshots = 'pending_screenshots';
  static const String _keyBrightness = 'brightness';
  static const String _keyVolume = 'volume';

  final SharedPreferences prefs;

  AppStateManager({required this.prefs});

  // Save current playback state
  Future<void> savePlaybackState({
    required int? playlistId,
    required int mediaIndex,
    required bool isPlaying,
  }) async {
    try {
      if (playlistId != null) {
        await prefs.setInt(_keyCurrentPlaylistId, playlistId);
      }
      await prefs.setInt(_keyCurrentMediaIndex, mediaIndex);
      await prefs.setBool(_keyIsPlaying, isPlaying);
      await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());

      AppLogger.info(
        '💾 [STATE] Saved playback state: playlist=$playlistId, index=$mediaIndex, playing=$isPlaying',
      );
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to save playback state', e);
    }
  }

  // Restore playback state
  Future<Map<String, dynamic>?> restorePlaybackState() async {
    try {
      final playlistId = prefs.getInt(_keyCurrentPlaylistId);
      final mediaIndex = prefs.getInt(_keyCurrentMediaIndex);
      final isPlaying = prefs.getBool(_keyIsPlaying);
      final lastSyncTime = prefs.getString(_keyLastSyncTime);

      if (playlistId == null || mediaIndex == null) {
        AppLogger.info('📭 [STATE] No saved playback state found');
        return null;
      }

      final state = {
        'playlist_id': playlistId,
        'media_index': mediaIndex,
        'is_playing': isPlaying ?? false,
        'last_sync_time': lastSyncTime,
      };

      AppLogger.info('📂 [STATE] Restored playback state: $state');
      return state;
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to restore playback state', e);
      return null;
    }
  }

  // Clear playback state
  Future<void> clearPlaybackState() async {
    try {
      await prefs.remove(_keyCurrentPlaylistId);
      await prefs.remove(_keyCurrentMediaIndex);
      await prefs.remove(_keyIsPlaying);
      await prefs.remove(_keyLastSyncTime);

      AppLogger.info('🗑️ [STATE] Cleared playback state');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to clear playback state', e);
    }
  }

  // Save pending screenshot for later upload
  Future<void> addPendingScreenshot({
    required String deviceId,
    required int mediaId,
    required String imagePath,
  }) async {
    try {
      final pending = getPendingScreenshots();
      pending.add({
        'device_id': deviceId,
        'media_id': mediaId,
        'image_path': imagePath,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_keyPendingScreenshots, jsonEncode(pending));

      AppLogger.info('📸 [STATE] Added pending screenshot: mediaId=$mediaId, path=$imagePath');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to add pending screenshot', e);
    }
  }

  // Get all pending screenshots
  List<Map<String, dynamic>> getPendingScreenshots() {
    try {
      final jsonString = prefs.getString(_keyPendingScreenshots);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to get pending screenshots', e);
      return [];
    }
  }

  // Remove a pending screenshot after successful upload
  Future<void> removePendingScreenshot(Map<String, dynamic> screenshot) async {
    try {
      final pending = getPendingScreenshots();
      pending.removeWhere((s) =>
          s['device_id'] == screenshot['device_id'] &&
          s['media_id'] == screenshot['media_id'] &&
          s['timestamp'] == screenshot['timestamp']);

      await prefs.setString(_keyPendingScreenshots, jsonEncode(pending));

      AppLogger.info('🗑️ [STATE] Removed pending screenshot: ${screenshot['media_id']}');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to remove pending screenshot', e);
    }
  }

  // Clear all pending screenshots
  Future<void> clearPendingScreenshots() async {
    try {
      await prefs.remove(_keyPendingScreenshots);
      AppLogger.info('🗑️ [STATE] Cleared all pending screenshots');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to clear pending screenshots', e);
    }
  }

  // Save brightness
  Future<void> saveBrightness(double brightness) async {
    try {
      await prefs.setDouble(_keyBrightness, brightness);
      AppLogger.info('💾 [STATE] Saved brightness: $brightness');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to save brightness', e);
    }
  }

  // Get saved brightness
  double? getSavedBrightness() {
    try {
      return prefs.getDouble(_keyBrightness);
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to get saved brightness', e);
      return null;
    }
  }

  // Save volume
  Future<void> saveVolume(double volume) async {
    try {
      await prefs.setDouble(_keyVolume, volume);
      AppLogger.info('💾 [STATE] Saved volume: $volume');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to save volume', e);
    }
  }

  // Get saved volume
  double? getSavedVolume() {
    try {
      return prefs.getDouble(_keyVolume);
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to get saved volume', e);
      return null;
    }
  }

  // Check if app needs synchronization (e.g., after power loss)
  bool needsSynchronization() {
    final lastSyncTime = prefs.getString(_keyLastSyncTime);
    if (lastSyncTime == null) return false;

    try {
      final lastSync = DateTime.parse(lastSyncTime);
      final now = DateTime.now();
      final difference = now.difference(lastSync);

      // If last sync was more than 5 minutes ago, we might need to sync
      final needsSync = difference.inMinutes > 5;

      if (needsSync) {
        AppLogger.info(
          '🔄 [STATE] App needs synchronization (last sync: ${difference.inMinutes} minutes ago)',
        );
      }

      return needsSync;
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to check sync status', e);
      return false;
    }
  }

  // Mark sync as completed
  Future<void> markSyncCompleted() async {
    try {
      await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
      AppLogger.info('✅ [STATE] Marked sync as completed');
    } catch (e) {
      AppLogger.error('⚠️ [STATE] Failed to mark sync completed', e);
    }
  }
}
