import 'package:get_it/get_it.dart';
import 'package:vizlearn/data/repositories/library_repository.dart';

import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

final getIt = GetIt.I;

void registerLibraryDependencies() {
  getIt.registerLazySingleton<LibraryRepository>(
        () => LibraryRepository(getIt<APIService>(), getIt<ApiCacheManager>()),
  );
}

