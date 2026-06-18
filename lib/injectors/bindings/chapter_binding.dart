import 'package:get/get.dart';
import '../../views/screens/library/controllers/chapter_controller.dart';

class ChapterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChapterController>(() => ChapterController());
  }
}

