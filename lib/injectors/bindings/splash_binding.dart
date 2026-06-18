import 'package:get/get.dart';
import '../../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put() instead of lazyPut for splash since we need it immediately
    Get.put<SplashController>(SplashController());
  }
}

