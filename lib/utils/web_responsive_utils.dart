import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/utils/app_export.dart';


class WebResponsiveUtils {
  static EdgeInsets webPadding(BuildContext context) => EdgeInsets.symmetric(
      horizontal: (MediaQuery.of(context).size.width > 1000
          ? 300
          : MediaQuery.of(context).size.width < 470
              ? 16
              : MediaQuery.of(context).size.width / 4));

  //static int get responsiveGridItemCount => Get.size.width > 750 ? 2 : 1;
  static int responsiveGridItemCount(BuildContext context) {
    return MediaQuery.of(context).size.width > 750 ? 2 : 1;
  }

  static double get responsiveButtonWidth =>
      Get.size.width < 600 ? Get.size.width : Get.size.width * 0.5;

  static double get responsiveWidth =>
      Get.size.width > 600 ? 600 : Get.size.width;


  static Widget _buildIconButton(
      String iconName, int index, Widget screen, int currentWebIndex) {
    return GestureDetector(
      onTap: () => Get.offAll(() => screen),
      child: Container(
        height: 40,
        width: 40,
        margin: Get.size.width < 500
            ? const EdgeInsets.symmetric(horizontal: 3)
            : const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: currentWebIndex == index
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomImageView(
            imagePath:
                "assets/icons/${currentWebIndex == index ? '$iconName.svg' : '${iconName}_outlined.svg'}",
            color: Colors.white,
            width: 14,
          ),
        ),
      ),
    );
  }
}
