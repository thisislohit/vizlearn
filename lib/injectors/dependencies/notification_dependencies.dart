import 'package:get_it/get_it.dart';

import '../../controllers/notification_controller.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

final getIt = GetIt.I;

void registerNotificationDependencies() {
  // Register NotificationRepository
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(getIt<APIService>(), getIt<ApiCacheManager>()),
  );

  // Register NotificationController
  getIt.registerLazySingleton<NotificationController>(
    () => NotificationController(getIt<NotificationRepository>()),
  );
}
