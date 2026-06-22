import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sync_controller.dart';
import '../injectors/configure_dependencies.dart';
import '../injectors/bindings/sync_binding.dart';
import '../routes/app_routes.dart';
import '../utils/cache/cache_keys.dart';
import '../utils/cache/secure_local_storage.dart';
import '../services/fcm_service.dart';
import '../views/screens/side_menu/profile/controllers/profile_controller.dart';
import '../injectors/bindings/profile_binding.dart';
import '../views/widgets/sync_progress_dialog.dart';

class SplashController extends GetxController {
  final SecureLocalStorage _secureStorage = getIt<SecureLocalStorage>();

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _navigate();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize FCM service
      final fcmService = getIt<FCMService>();
      await fcmService.initializeFCM();
    } catch (e) {
      print('❌ Error initializing FCM in splash: $e');
    }
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    // Initialize sync controller
    SyncBinding().dependencies();
    if (!Get.isRegistered<SyncController>()) {
      // If sync controller not registered, proceed without sync
      _proceedToNextScreen();
      return;
    }

    final syncController = Get.find<SyncController>();
    final isFirstTime = await syncController.isFirstTimeSync();

    if (isFirstTime) {
      // Show progress dialog for first-time sync
      final context = Get.context;
      if (context != null) {
        SyncProgressDialog.show(
          context: context,
          syncController: syncController,
          allowCancel: false,
        );

        try {
          // Use syncAll to handle everything. It will call syncCmsApis,
          // syncProfileAndCategories, and mark complete.
          await syncController.syncAll(
            showDialog: false,
            onBlockingComplete: () {
              // Not needed here but required by signature
            },
          );

          // Close dialog on success
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          // Close dialog even on error
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          // Continue navigation even if sync fails so user isn't stuck
        }
      }
    }

    _proceedToNextScreen();
  }

  void _proceedToNextScreen() {
    _secureStorage.load(key: CacheKeys.token).then((token) async {
      if (token.isNotEmpty) {
        // Initialize profile controller and fetch profile data
        ProfileBinding().dependencies();
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          // Load from cache first (happens in onInit), then fetch from API in background
          // This ensures cached data is shown immediately while API updates in background
          profileController.fetchProfile();
        }
        Get.offAllNamed(AppRoutes.home);
      } else {
        final hasSeenOnboarding = await _secureStorage.load(key: CacheKeys.hasSeenOnboarding);
        if (hasSeenOnboarding == 'true') {
          Get.offAllNamed(AppRoutes.arModeSelection);
        } else {
          Get.offAllNamed(AppRoutes.onboarding);
        }
      }
    });
  }
}
