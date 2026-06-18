import 'package:get/get.dart';

import 'bindings/login_binding.dart';
import 'bindings/notification_binding.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    LoginBinding().dependencies();
    NotificationBinding().dependencies();
  }
}
