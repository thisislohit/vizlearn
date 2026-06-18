import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/utils/app_export.dart';
import '../../../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomImageView(
            imagePath: Assets.images.splashBg.path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Align(
            alignment: Alignment.center,
            child: CustomImageView(
              imagePath: Assets.images.vizlearnLogo.path,
              width: Get.size.width * 0.8,
            ),
          )
        ],
      ),
    );
  }
}
