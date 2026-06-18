import 'package:get/get.dart';

import '../../controllers/side_menu/contact_us_controller.dart';
import '../../data/repositories/side_menu/contact_us_repository.dart';
import '../../injectors/configure_dependencies.dart';
import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

class ContactUsBinding extends Bindings {
  @override
  void dependencies() {
    final apiService = getIt<APIService>();
    final cacheManager = getIt<ApiCacheManager>();

    final repository = ContactUsRepository(apiService, cacheManager);

    Get.lazyPut<ContactUsController>(() => ContactUsController(repository));
  }
}

