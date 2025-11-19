import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/data/datasources/remote/websocket_datasource.dart';

/// Device memory and storage monitoring service
/// Sends periodic updates about device memory status via WebSocket
class DeviceMemoryMonitor {
  final WebSocketDataSource webSocketDataSource;

  /// Callback to get ready playlist IDs from the app
  Future<List<int>> Function()? getReadyPlaylistIds;

  Timer? _monitoringTimer;
  static const int _monitoringIntervalSeconds = 60; // Report every 60 seconds

  DeviceMemoryMonitor({
    required this.webSocketDataSource,
    this.getReadyPlaylistIds,
  });

  /// Set the callback to get ready playlist IDs
  /// This should be called by the app after initialization
  void setReadyPlaylistIdsCallback(Future<List<int>> Function() callback) {
    getReadyPlaylistIds = callback;
    AppLogger.deviceInfo('✅ Ready playlists callback registered with DeviceMemoryMonitor');
  }

  /// Start monitoring device memory
  void startMonitoring() {
    AppLogger.deviceInfo('📊 Starting device memory monitoring');

    // Send initial report
    _sendMemoryReport();

    // Schedule periodic reports
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: _monitoringIntervalSeconds), (_) => _sendMemoryReport());
  }

  /// Stop monitoring
  void stopMonitoring() {
    AppLogger.deviceInfo('⏹️ Stopping device memory monitoring');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Gather memory information and send via WebSocket
  Future<void> _sendMemoryReport() async {
    try {
      final memoryInfo = await _getMemoryInfo();

      if (webSocketDataSource.isConnected) {
        await webSocketDataSource.sendMessage({'type': 'device_status', 'data': memoryInfo});

        final readyPlaylists = memoryInfo['ready_playlists'] as List<int>?;
        final playlistCount = readyPlaylists?.length ?? 0;
        AppLogger.deviceInfo('📤 Memory report sent with $playlistCount ready playlists: $memoryInfo');
      } else {
        AppLogger.deviceInfo('⚠️ Cannot send memory report: WebSocket not connected');
      }
    } catch (e) {
      AppLogger.deviceError('Failed to send memory report', e);
    }
  }

  /// Get current memory and storage information
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      // Get storage information
      final storageInfo = await _getStorageInfo();

      // Get memory information (approximation)
      final memoryInfo = _getMemoryInfoFromSystem();

      // Get ready playlist IDs
      List<int> readyPlaylistIds = [];
      if (getReadyPlaylistIds != null) {
        try {
          readyPlaylistIds = await getReadyPlaylistIds!();
          AppLogger.deviceInfo('📋 Including ${readyPlaylistIds.length} ready playlists in memory report');
        } catch (e) {
          AppLogger.deviceError('Failed to get ready playlist IDs', e);
        }
      }

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'storage': storageInfo,
        'memory': memoryInfo,
        'ready_playlists': readyPlaylistIds,
      };
    } catch (e) {
      AppLogger.deviceError('Failed to gather memory info', e);
      return {'timestamp': DateTime.now().toIso8601String(), 'error': e.toString()};
    }
  }

  /// Get storage information for application directory
  Future<Map<String, dynamic>> _getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // Get total and free space
      final stat = await FileStat.stat(path);

      // Calculate used space by traversing the directory
      int usedBytes = await _calculateDirectorySize(directory);

      // Note: Getting total/free disk space is platform-specific
      // For Android, we'll use basic file system info
      return {
        'path': path,
        'used_bytes': usedBytes,
        'used_mb': (usedBytes / (1024 * 1024)).toStringAsFixed(2),
        'used_gb': (usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2),
        'last_modified': stat.modified.toIso8601String(),
      };
    } catch (e) {
      AppLogger.deviceError('Failed to get storage info', e);
      return {'error': e.toString()};
    }
  }

  /// Calculate total size of a directory recursively
  Future<int> _calculateDirectorySize(Directory directory) async {
    int totalSize = 0;

    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            totalSize += size;
          } catch (e) {
            // Skip files that can't be accessed
            continue;
          }
        }
      }
    } catch (e) {
      AppLogger.deviceError('Error calculating directory size', e);
    }

    return totalSize;
  }

  /// Get memory information from system
  /// Note: Accurate memory info requires platform-specific code
  Map<String, dynamic> _getMemoryInfoFromSystem() {
    try {
      // For Android, we would need platform channel to get accurate memory info
      // This is a placeholder that can be extended with platform channels

      return {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'note': 'Detailed memory info requires platform channels',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Send memory report immediately (on-demand)
  Future<void> sendMemoryReportNow() async {
    AppLogger.deviceInfo('📊 Sending on-demand memory report');
    await _sendMemoryReport();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
