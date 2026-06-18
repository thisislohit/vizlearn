import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:get/get.dart';

class DrawerController extends GetxController {
  final AdvancedDrawerController advancedDrawerController = AdvancedDrawerController();

  void openDrawer() {
    advancedDrawerController.showDrawer();
  }

  void closeDrawer() {
    advancedDrawerController.hideDrawer();
  }

  void toggleDrawer() {
    advancedDrawerController.toggleDrawer();
  }
}

