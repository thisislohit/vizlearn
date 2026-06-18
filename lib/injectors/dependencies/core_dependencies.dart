import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

import '../../services/api_service.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_handler_service.dart';
import '../../utils/api/api_interceptor.dart';
import '../../utils/cache/api_cache_manager.dart';
import '../../utils/cache/secure_local_storage.dart';
import '../../utils/cache/shared_preference.dart';

final getIt = GetIt.I;

void registerCoreDependencies() {
  // Register Secure Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  getIt.registerLazySingleton<SecureLocalStorage>(
    () => SecureLocalStorage(getIt<FlutterSecureStorage>()),
  );

  getIt.registerLazySingleton<SharedPreferenceStorage>(
    () => SharedPreferenceStorage(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<ApiCacheManager>(() => ApiCacheManager());

  // Register ApiInterceptor
  getIt.registerLazySingleton<ApiInterceptor>(
    () => ApiInterceptor(getIt<SecureLocalStorage>()),
  );

  // Register Dio with interceptors
  getIt.registerLazySingleton<Dio>(
    () => Dio()..interceptors.add(getIt<ApiInterceptor>()),
  );

  getIt.registerLazySingleton<APIService>(() => APIService(getIt<Dio>()));

  // Register notification services
  getIt.registerLazySingleton<FCMService>(() => FCMService());

  getIt.registerLazySingleton<NotificationHandlerService>(
    () => NotificationHandlerService(),
  );
}
