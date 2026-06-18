import 'package:get/get.dart';
import '../../controllers/sync_controller.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/side_menu/cms_repository.dart';
import '../../data/repositories/side_menu/contact_us_repository.dart';
import '../../injectors/configure_dependencies.dart';
import '../../services/api_service.dart';
import '../../utils/cache/api_cache_manager.dart';

class SyncBinding extends Bindings {
  @override
  void dependencies() {
    final apiService = getIt<APIService>();
    final cacheManager = getIt<ApiCacheManager>();
    final profileRepository = getIt<ProfileRepository>();
    
    // CMS and ContactUs repositories are not in GetIt, create them directly
    final cmsRepository = CMSRepository(apiService, cacheManager);
    final contactUsRepository = ContactUsRepository(apiService, cacheManager);

    if (!Get.isRegistered<SyncController>()) {
      Get.put<SyncController>(
        SyncController(
          apiService: apiService,
          cacheManager: cacheManager,
          profileRepository: profileRepository,
          cmsRepository: cmsRepository,
          contactUsRepository: contactUsRepository,
        ),
        permanent: true,
      );
    }
  }
}

