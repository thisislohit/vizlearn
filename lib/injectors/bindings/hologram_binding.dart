import 'package:get/get.dart';
import '../../controllers/connection_controller.dart';
import '../../controllers/hologram_controller.dart';

class HologramBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ConnectionController>(ConnectionController(), permanent: true);
    Get.put<HologramController>(HologramController(), permanent: true);
  }
}

