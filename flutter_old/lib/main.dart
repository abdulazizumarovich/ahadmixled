import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:tv_monitor/app.dart';
import 'package:tv_monitor/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Android TV landscape orientation (uncomment if needed)
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.landscapeLeft,
  //   DeviceOrientation.landscapeRight,
  // ]);

  // Initialize dependencies
  await di.init();

  runApp(const AdPlayerApp());
}
