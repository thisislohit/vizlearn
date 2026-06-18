import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../injectors/bindings/bottom_nav_binding.dart';

class BottomNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _updateIndexFromRoute();
  }

  @override
  void onReady() {
    super.onReady();
    // Update index when controller is ready (after route is fully loaded)
    _updateIndexFromRoute();
  }

  /// Automatically updates the current index based on the current route
  void _updateIndexFromRoute() {
    final currentRoute = Get.currentRoute;
    final index = _getIndexFromRoute(currentRoute);
    if (index != null && currentIndex.value != index) {
      currentIndex.value = index;
    }
  }

  /// Maps route names to bottom nav indices
  int? _getIndexFromRoute(String route) {
    switch (route) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.basicControls:
        return 1;
      case AppRoutes.advancedControls:
        return 2;
      case AppRoutes.deviceSpecs:
        return 3;
      default:
        return null; // Not a bottom nav route
    }
  }

  /// Changes the bottom nav index and navigates to the corresponding route
  void changeIndex(int index) {
    if (currentIndex.value == index) return; // Already on this tab
    currentIndex.value = index;
    _navigateToRoute(index);
  }

  /// Navigates to the route corresponding to the given index
  void _navigateToRoute(int index) {
    String route;
    switch (index) {
      case 0:
        route = AppRoutes.home;
        break;
      case 1:
        route = AppRoutes.basicControls;
        break;
      case 2:
        route = AppRoutes.advancedControls;
        break;
      case 3:
        route = AppRoutes.deviceSpecs;
        break;
      default:
        return;
    }
    
    // Ensure bindings are initialized before navigation
    if (!Get.isRegistered<BottomNavController>()) {
      BottomNavBinding().dependencies();
    }
    
    // Navigate using route name to ensure bindings are called
    // Transitions are configured in app_routes.dart
    Get.offAllNamed(route);
    
    // Update index after navigation (in case route changes)
    Future.microtask(() => _updateIndexFromRoute());
  }
}

