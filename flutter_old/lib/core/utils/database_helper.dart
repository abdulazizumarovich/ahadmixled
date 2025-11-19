import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  /// Clear Isar database completely (use only for testing or migration)
  static Future<void> clearDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/default.isar');
      final lockFile = File('${dir.path}/default.isar.lock');

      if (await dbFile.exists()) {
        await dbFile.delete();
        print('Database file deleted successfully');
      }

      if (await lockFile.exists()) {
        await lockFile.delete();
        print('Database lock file deleted successfully');
      }

      print('Database cleared successfully');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }
}
