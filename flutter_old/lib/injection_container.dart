import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/api_constants.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/retry_interceptor.dart';
import 'core/utils/network_info.dart';
import 'features/data/services/websocket_reconnection_service.dart';
import 'features/data/services/device_memory_monitor.dart';
import 'features/data/services/app_state_manager.dart';
import 'features/data/services/background_download_service.dart';
import 'features/presentation/services/playlist_controller_manager.dart';
import 'features/data/datasources/local/auth_local_datasource.dart';
import 'features/data/datasources/local/device_local_datasource.dart';
import 'features/data/datasources/local/permission_local_datasource.dart';
import 'features/data/datasources/local/video_local_datasource.dart';
import 'features/data/datasources/remote/auth_remote_datasource.dart';
import 'features/data/datasources/remote/device_remote_datasource.dart';
import 'features/data/datasources/remote/video_remote_datasource.dart';
import 'features/data/datasources/remote/websocket_datasource.dart';
import 'features/data/models/playlist_model.dart';
import 'features/data/repositories_impl/auth_repository_impl.dart';
import 'features/data/repositories_impl/device_repository_impl.dart';
import 'features/data/repositories_impl/permission_repository_impl.dart';
import 'features/data/repositories_impl/video_repository_impl.dart';
import 'features/data/repositories_impl/websocket_repository_impl.dart';
import 'features/domain/repositories/auth_repository.dart';
import 'features/domain/repositories/device_repository.dart';
import 'features/domain/repositories/permission_repository.dart';
import 'features/domain/repositories/video_repository.dart';
import 'features/domain/repositories/websocket_repository.dart';
import 'features/domain/usecases/auth/login_usecase.dart';
import 'features/domain/usecases/auth/logout_usecase.dart';
import 'features/domain/usecases/auth/refresh_token_usecase.dart';
import 'features/domain/usecases/auth/check_auth_status_usecase.dart';
import 'features/domain/usecases/device/get_device_info_usecase.dart';
import 'features/domain/usecases/device/register_device_usecase.dart';
import 'features/domain/usecases/permission/request_permission_usecase.dart';
import 'features/domain/usecases/video/capture_screenshot_usecase.dart';
import 'features/domain/usecases/video/get_device_screens_usecase.dart';
import 'features/domain/usecases/video/download_playlist_usecase.dart';
import 'features/domain/usecases/video/get_local_playlists_usecase.dart';
import 'features/domain/usecases/video/send_playlist_status_usecase.dart';
import 'features/domain/usecases/video/delete_playlist_usecase.dart';
import 'features/domain/usecases/video/redownload_media_item_usecase.dart';
import 'features/domain/usecases/websocket/connect_websocket_usecase.dart';
import 'features/presentation/blocs/auth/auth_bloc.dart';
import 'features/presentation/blocs/device/device_bloc.dart';
import 'features/presentation/blocs/video/video_bloc.dart';
import 'features/presentation/blocs/websocket/websocket_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(
    () => AuthBloc(loginUseCase: sl(), refreshTokenUseCase: sl(), logoutUseCase: sl(), checkAuthStatusUseCase: sl()),
  );

  sl.registerLazySingleton(
    () => VideoBloc(
      getDeviceScreensUseCase: sl(),
      downloadPlaylistUseCase: sl(),
      getLocalPlaylistsUseCase: sl(),
      sendPlaylistStatusUseCase: sl(),
      deletePlaylistUseCase: sl(),
      captureScreenshotUseCase: sl(),
      redownloadMediaItemUseCase: sl(),
      deviceLocalDataSource: sl(),
    ),
  );

  sl.registerFactory(() => DeviceBloc(getDeviceInfoUseCase: sl(), registerDeviceUseCase: sl()));

  sl.registerFactory(
    () => WebSocketBloc(
      connectWebSocketUseCase: sl(),
      webSocketRepository: sl(),
      videoBloc: sl(),
      deviceLocalDataSource: sl(),
    ),
  );

  // Use Cases - Auth
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(repository: sl()));
  sl.registerLazySingleton(() => LogoutUseCase(repository: sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(repository: sl()));

  // Use Cases - Device
  sl.registerLazySingleton(() => GetDeviceInfoUseCase(repository: sl()));
  sl.registerLazySingleton(() => RegisterDeviceUseCase(repository: sl()));

  // Use Cases - Video
  sl.registerLazySingleton(() => GetDeviceScreensUseCase(sl()));
  sl.registerLazySingleton(() => DownloadPlaylistUseCase(sl()));
  sl.registerLazySingleton(() => GetLocalPlaylistsUseCase(sl()));
  sl.registerLazySingleton(() => SendPlaylistStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeletePlaylistUseCase(sl()));
  sl.registerLazySingleton(() => CaptureScreenshotUseCase(repository: sl()));
  sl.registerLazySingleton(() => RedownloadMediaItemUseCase(sl()));

  // Use Cases - WebSocket
  sl.registerLazySingleton(() => ConnectWebSocketUseCase(repository: sl()));

  // Use Cases - Permission
  sl.registerLazySingleton(() => RequestPermissionUseCase(repository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));

  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      webSocketDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<DeviceRepository>(() => DeviceRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));

  sl.registerLazySingleton<WebSocketRepository>(() => WebSocketRepositoryImpl(dataSource: sl()));

  sl.registerLazySingleton<PermissionRepository>(() => PermissionRepositoryImpl(localDataSource: sl()));

  // Data Sources - Remote
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(dio: sl()));

  sl.registerLazySingleton<DeviceRemoteDataSource>(() => DeviceRemoteDataSourceImpl(dio: sl()));

  sl.registerLazySingleton<VideoRemoteDataSource>(() => VideoRemoteDataSourceImpl(dio: sl()));

  sl.registerLazySingleton<WebSocketDataSource>(() => WebSocketDataSourceImpl());

  // Data Sources - Local
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sharedPreferences: sl()));

  sl.registerLazySingleton<DeviceLocalDataSource>(
    () => DeviceLocalDataSourceImpl(deviceInfo: sl(), packageInfo: sl(), sharedPreferences: sl()),
  );

  sl.registerLazySingleton<VideoLocalDataSource>(() => VideoLocalDataSourceImpl(isar: sl()));

  sl.registerLazySingleton<PermissionLocalDataSource>(() => PermissionLocalDataSourceImpl(sharedPreferences: sl()));

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(connectivity: sl()));

  // Services
  sl.registerLazySingleton(() => WebSocketReconnectionService(webSocketDataSource: sl()));
  sl.registerLazySingleton(() => DeviceMemoryMonitor(webSocketDataSource: sl()));
  sl.registerLazySingleton(() => AppStateManager(prefs: sl()));
  sl.registerLazySingleton(() => BackgroundDownloadService(downloadPlaylistUseCase: sl()));
  sl.registerLazySingleton(() => PlaylistControllerManager());

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {'Content-Type': ApiConstants.contentType},
    ),
  );

  // Register Dio first so it can be used by data sources
  sl.registerLazySingleton(() => dio);

  // Add Retry Interceptor first (for automatic retries on failures)
  dio.interceptors.add(RetryInterceptor(dio: dio));

  // Add Auth Interceptor after Dio is registered
  // This interceptor automatically adds tokens to requests and handles 401 errors
  dio.interceptors.add(
    AuthInterceptor(localDataSource: sl<AuthLocalDataSource>(), remoteDataSource: sl<AuthRemoteDataSource>(), dio: dio),
  );

  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => DeviceInfoPlugin());

  final packageInfo = await PackageInfo.fromPlatform();
  sl.registerLazySingleton(() => packageInfo);

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([PlaylistModelSchema], directory: dir.path);
  sl.registerLazySingleton(() => isar);
}
