import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../../injectors/configure_dependencies.dart';
import '../../utils/cache/secure_local_storage.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    final authRepository = getIt<AuthRepository>();
    final secureStorage = getIt<SecureLocalStorage>();

    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: authRepository,
        secureStorage: secureStorage,
      ),
    );
  }
}

