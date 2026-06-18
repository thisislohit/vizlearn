import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import '../../controllers/drawer_controller.dart' as DrawerCtrl;
import '../../controllers/hologram_controller.dart';
import '../../views/screens/side_menu/profile/controllers/profile_controller.dart';
import 'custom_app_bar.dart';
import 'custom_image_view.dart';
import 'custom_shaking_notification_icon.dart';
import 'custom_switch.dart';

class CustomHomeAppBar extends StatelessWidget {
  const CustomHomeAppBar({super.key});

  /// Returns greeting based on current time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning...';
    } else if (hour < 17) {
      return 'Good Afternoon...';
    } else if (hour < 21) {
      return 'Good Evening...';
    } else {
      return 'Good Night...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerCtrl = Get.find<DrawerCtrl.DrawerController>();
    final hologramController =
        Get.isRegistered<HologramController>() ? Get.find<HologramController>() : null;
    final profileController = Get.isRegistered<ProfileController>() 
        ? Get.find<ProfileController>() 
        : null;
    
    return CustomAppBar(
      height: 80,
      leadingBack: false,
      leadingWidth: 16,
      titleWidget: Row(
        children: [
          GestureDetector(
            onTap: () => drawerCtrl.openDrawer(),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.white, width: 1),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: profileController != null
                  ? Obx(() => CustomImageView(
                        imagePath: profileController.schoolImageUrl.isNotEmpty
                            ? profileController.schoolImageUrl
                            : profileController.avatarPath.value,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ))
                  : CustomImageView(
                      imagePath: Assets.icons.profilePng.path,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          12.wS,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: AppFont.w400.s14),
                4.hS,
                profileController != null
                    ? Obx(() => Text(
                          profileController.schoolName,
                          style: AppFont.w700.s18,
                        ))
                    : Text('School Admin', style: AppFont.w700.s18),
              ],
            ),
          ),
          if (hologramController != null)
            Obx(() {
              if (!hologramController.isReady) return const SizedBox.shrink();
              return CustomSwitchWithText(
                value: hologramController.isDevicePowerOn.value,
                onChanged: (val) => hologramController.setDevicePower(val),
              );
            }),
        ],
      ),
      centerTitle: false,
      actions: [
        const ShakingNotificationIcon(),
        16.wS,
      ],
    );
  }
}

