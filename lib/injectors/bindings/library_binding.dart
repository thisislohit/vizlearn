import 'package:get/get.dart';

import '../../controllers/library_controller.dart';
import '../../data/repositories/library_repository.dart';
import '../../injectors/configure_dependencies.dart';
import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    final apiService = getIt<APIService>();
    final cacheManager = getIt<ApiCacheManager>();
    final repository = LibraryRepository(apiService, cacheManager);

    Get.lazyPut<LibraryController>(() => LibraryController(repository));
  }
}

