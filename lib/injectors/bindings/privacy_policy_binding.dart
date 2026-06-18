import 'package:get/get.dart';

import '../../controllers/side_menu/cms_controller.dart';
import '../../data/repositories/side_menu/cms_repository.dart';
import '../../injectors/configure_dependencies.dart';
import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

class PrivacyPolicyBinding extends Bindings {
  @override
  void dependencies() {
    final apiService = getIt<APIService>();
    final cacheManager = getIt<ApiCacheManager>();
    final repository = CMSRepository(apiService, cacheManager);

    Get.lazyPut<PrivacyPolicyController>(
      () => PrivacyPolicyController(repository),
    );
  }
}

