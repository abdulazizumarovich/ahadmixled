import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tv_monitor/injection_container.dart';
import 'package:tv_monitor/features/presentation/blocs/auth/auth_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/device/device_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/video/video_bloc.dart';
import 'package:tv_monitor/features/presentation/blocs/websocket/websocket_bloc.dart';
import 'package:tv_monitor/features/presentation/screens/splash_screen.dart';

class AdPlayerApp extends StatelessWidget {
  const AdPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
        BlocProvider<VideoBloc>(create: (context) => sl<VideoBloc>()),
        BlocProvider<DeviceBloc>(create: (context) => sl<DeviceBloc>()),
        BlocProvider<WebSocketBloc>(create: (context) => sl<WebSocketBloc>()),
      ],
      child: MaterialApp(
        title: 'AdPlayer - TV Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark, useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
  }
}
