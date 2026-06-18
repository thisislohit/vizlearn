import 'package:get/get.dart';
import '../../views/screens/side_menu/technologies/controllers/technologies_controller.dart';

class TechnologiesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TechnologiesController>(() => TechnologiesController());
  }
}

