import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import '../../../controllers/onboarding_controller.dart';

class OnboardingScreens extends GetView<OnboardingController> {
  const OnboardingScreens({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isTab = Get.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            itemCount: controller.images.length,
            itemBuilder: (context, index) {
              return _buildOnboardingPage(index, isTab);
            },
          ),
          // Finish button on last page
          Obx(
            () => Positioned(
              bottom: isTab ? 60 : 44,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Center(
                    child: TextButton(
                      onPressed: controller.onFinish,
                      child: Text(
                        controller.currentPage.value ==
                                controller.images.length - 1
                            ? 'Finish'
                            : 'Skip',
                        style: (isTab ? AppFont.w700.s20 : AppFont.w700.s16)
                            .copyWith(color: AppColors.white),
                      ),
                    ),
                  ),
                  (isTab ? 24 : 16).hS,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTab ? 60 : 16),
                    child: Row(
                      mainAxisAlignment: isTab ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                      children: [
                        CustomElevatedButton2(
                          text: 'About Us',
                          color: AppColors.buttonPrimary,
                          width: isTab ? 200 : Get.size.width * 0.44,
                          onPressed: () {
                            Get.toNamed(AppRoutes.aboutUs);
                          },
                        ),
                        if (isTab) 24.wS,
                        CustomElevatedButton2(
                          text: 'Contact Us',
                          color: AppColors.buttonSecondary,
                          width: isTab ? 200 : Get.size.width * 0.44,
                          onPressed: () {
                            Get.toNamed(AppRoutes.contactUs);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(int index, bool isTab) {
    return Stack(
      children: [
        CustomImageView(
          imagePath: controller.images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: double.infinity, height: isTab ? 180 : 120),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTab ? 100 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.firstLine[index],
                    style: (isTab ? AppFont.w700.s36 : AppFont.w700.s24)
                        .copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  (isTab ? 16 : 8).hS,
                  Text(
                    controller.secondLine[index],
                    style: (isTab ? AppFont.w400.s80 : AppFont.w400.s50)
                        .copyWith(color: Colors.white, fontFamily: 'Bebas'),
                    textAlign: TextAlign.center,
                  ),
                  (isTab ? 16 : 8).hS,
                  Text(
                    controller.thirdLine[index],
                    style: (isTab ? AppFont.w500.s30 : AppFont.w500.s20)
                        .copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
