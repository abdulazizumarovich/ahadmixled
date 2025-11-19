import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tv_monitor/core/utils/app_logger.dart';
import 'package:tv_monitor/features/domain/entities/auth_entity.dart';
import 'package:tv_monitor/features/domain/usecases/auth/login_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/auth/logout_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:tv_monitor/features/domain/usecases/auth/check_auth_status_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.refreshTokenUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    AppLogger.authInfo('Login requested for user: ${event.username}');
    emit(const AuthLoading());

    final result = await loginUseCase(LoginParams(username: event.username, password: event.password));

    result.fold(
      (failure) {
        AppLogger.authError('Login failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (auth) {
        AppLogger.authInfo('Login successful, user authenticated');
        emit(AuthAuthenticated(auth: auth));
      },
    );
  }

  Future<void> _onRefreshTokenRequested(RefreshTokenRequested event, Emitter<AuthState> emit) async {
    final result = await refreshTokenUseCase(RefreshTokenParams(refreshToken: event.refreshToken));

    result.fold((failure) => emit(AuthError(message: failure.message)), (auth) => emit(AuthAuthenticated(auth: auth)));
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    AppLogger.authInfo('Logout requested');
    await logoutUseCase();
    AppLogger.authInfo('User logged out successfully');
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    AppLogger.authInfo('Checking authentication status...');
    emit(const AuthLoading());

    final result = await checkAuthStatusUseCase();

    result.fold(
      (failure) {
        AppLogger.authInfo('Auth check failed, user not authenticated');
        emit(const AuthUnauthenticated());
      },
      (auth) {
        if (auth != null) {
          AppLogger.authInfo('Auth check successful, user is authenticated');
          emit(AuthAuthenticated(auth: auth));
        } else {
          AppLogger.authInfo('No valid auth found, user not authenticated');
          emit(const AuthUnauthenticated());
        }
      },
    );
  }
}
