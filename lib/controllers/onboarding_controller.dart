import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import '../routes/app_routes.dart';
import '../utils/cache/cache_keys.dart';
import '../utils/cache/secure_local_storage.dart';
import '../injectors/configure_dependencies.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  Timer? autoAdvanceTimer;
  final SecureLocalStorage _secureStorage = getIt<SecureLocalStorage>();

  final List<String> images = [
    Assets.images.onboarding1.path,
    Assets.images.onboarding2.path,
    Assets.images.onboarding3.path,
  ];

  final List<String> firstLine = [
    'Step into the',
    'Immersive Education for the',
    'Bring your',
  ];

  final List<String> secondLine = [
    'Future of Learning',
    'Next Generation.',
    'Classroom to Life!',
  ];

  final List<String> thirdLine = [
    'The Power of 3D Learning in Every Classroom.',
    'Transforming Education, One 3D Learning Experience at a Time.',
    'Experience. Engage. Evolve with 3D Lessons.',
  ];

  @override
  void onInit() {
    super.onInit();
    startAutoAdvance();
  }

  void startAutoAdvance() {
    autoAdvanceTimer?.cancel();
    autoAdvanceTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (currentPage.value < images.length - 1) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
      }
    });
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    // Stop timer on last page, otherwise restart it
    if (index == images.length - 1) {
      autoAdvanceTimer?.cancel();
    } else {
      startAutoAdvance(); // Restart timer on page change
    }
  }

  void onFinish() async {
    autoAdvanceTimer?.cancel();
    await _secureStorage.save(key: CacheKeys.hasSeenOnboarding, value: 'true');
    Get.offNamed(
      AppRoutes.arModeSelection,
      arguments: {'preLogin': true},
    );
  }

  @override
  void onClose() {
    autoAdvanceTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}

