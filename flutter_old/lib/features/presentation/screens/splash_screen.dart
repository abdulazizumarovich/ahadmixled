import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tv_monitor/features/domain/usecases/permission/request_permission_usecase.dart';
import 'package:tv_monitor/injection_container.dart';
import 'package:tv_monitor/features/presentation/blocs/auth/auth_bloc.dart';
import 'package:tv_monitor/features/presentation/screens/login_screen.dart';
import 'package:tv_monitor/features/presentation/screens/loading_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    // Wait for 1 second to show splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Request storage permissions first
    await _requestPermissions();

    if (!mounted) return;

    // Check if user is authenticated
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  Future<void> _requestPermissions() async {
    try {
      final requestPermissionUseCase = sl<RequestPermissionUseCase>();
      await requestPermissionUseCase();
    } catch (e) {
      // Log error but continue - permissions can be requested later
      debugPrint('Permission request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // User is authenticated, navigate to loading screen for downloads
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoadingScreen()));
        } else if (state is AuthUnauthenticated) {
          // User is not authenticated, navigate to login
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tv, size: 100, color: Colors.cyanAccent.shade700),
              const SizedBox(height: 20),
              const Text(
                'AdPlayer',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text('TV Monitor System', style: TextStyle(fontSize: 20, color: Colors.white70)),
              const SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.cyanAccent.shade700),
            ],
          ),
        ),
      ),
    );
  }
}
