import 'package:get/get.dart';
import '../../views/screens/side_menu/profile/controllers/profile_controller.dart';
import '../../data/repositories/profile_repository.dart';
import '../../injectors/configure_dependencies.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final profileRepository = getIt<ProfileRepository>();

    if (!Get.isRegistered<ProfileController>()) {
      Get.put<ProfileController>(
        ProfileController(profileRepository: profileRepository),
        permanent: true,
      );
    }
  }
}

