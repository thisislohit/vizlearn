import 'package:get_it/get_it.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

final getIt = GetIt.I;

void registerAuthDependencies() {
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<APIService>()),
  );
  
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(getIt<APIService>(), getIt<ApiCacheManager>()),
  );
}

