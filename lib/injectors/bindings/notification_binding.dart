import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';
import '../../injectors/configure_dependencies.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put() with permanent flag to ensure it's always available
    // This is needed because SyncController accesses it during sync
    if (!Get.isRegistered<NotificationController>()) {
      Get.put<NotificationController>(
        getIt<NotificationController>(),
        permanent: true,
      );
    }
  }
}
