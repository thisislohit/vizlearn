import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:get/get.dart';
import 'package:vizlearn/controllers/auth_controller.dart';
import '../../../gen/assets.gen.dart';
import '../../../utils/app_export.dart';
import '../../../theme/app_font.dart';
import '../../../controllers/drawer_controller.dart' as DrawerCtrl;
import '../../../controllers/sync_controller.dart';
import '../../../controllers/hologram_controller.dart';
import '../../../controllers/connection_controller.dart';
import '../../../injectors/bindings/sync_binding.dart';
import 'widgets/custom_glass_confirmation_dialog.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/sync_progress_dialog.dart';

class SideMenu extends StatelessWidget {
  final Widget child;

  const SideMenu({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final drawerCtrl = Get.find<DrawerCtrl.DrawerController>();
    final authCtrl = Get.find<AuthController>();
    final bool isTab = Get.size.width > 600;

    return Stack(
      children: [
        AdvancedDrawer(
          controller: drawerCtrl.advancedDrawerController,
          openRatio: isTab ? 0.5 : 0.7,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          backdrop: Container(
            height: double.infinity,
            width: double.infinity,
            color: AppColors.primary,
            child: Transform.scale(
              scaleX: 1.0,
              scaleY: 2, // Stretch vertically to create vertical oval
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(
                      0.3,
                      -0.1,
                    ), // 50% horizontal, 39.65% from top
                    radius: 0.6, // Increased radius to spread the gradient more
                    colors: [
                      const Color(
                        0xFF2296F6,
                      ).withOpacity(0.4), // #118DF3 - semi-transparent
                      const Color(
                        0xFF031E58,
                      ).withOpacity(0.9), // #031E58 - semi-transparent
                    ],
                  ),
                ),
              ),
            ),
          ),
          childDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          drawer: _buildDrawer(context, drawerCtrl, authCtrl),
          child: child,
        ),
        Obx(
          () => authCtrl.isLoading.value
              ? Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CustomLoader(
                      message: 'Logging you out...',
                      style: LoaderStyle.dualRing,
                      showBackground: true,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    DrawerCtrl.DrawerController drawerCtrl,
    AuthController authCtrl,
  ) {
    return SafeArea(
      child: Column(
        children: [
          Spacer(flex: 1,),
          // Menu items
          Expanded(
            flex: 6,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuRouteItem(
                  icon: Assets.icons.profileSvg,
                  title: 'Profile',
                  route: AppRoutes.profile,
                  drawerCtrl: drawerCtrl,
                ),
                _buildMenuRouteItem(
                  icon: Assets.icons.technology,
                  title: 'Technologies',
                  route: AppRoutes.technologies,
                  drawerCtrl: drawerCtrl,
                ),
                _buildMenuRouteItem(
                  icon: Assets.icons.question,
                  title: 'Why Choose VizLearn',
                  route: AppRoutes.whyChooseVizlearn,
                  drawerCtrl: drawerCtrl,
                ),
                // _buildMenuRouteItem(
                //   icon: Assets.icons.content,
                //   title: 'Content Library',
                //   route: AppRoutes.contentLibrary,
                //   drawerCtrl: drawerCtrl,
                // ),
                // _buildMenuRouteItem(
                //   icon: Assets.icons.restart,
                //   title: 'Hologram Tester',
                //   route: AppRoutes.hologramTest,
                //   drawerCtrl: drawerCtrl,
                // ),
                _buildMenuRouteItem(
                  icon: Assets.icons.mail,
                  title: 'Contact Us',
                  route: AppRoutes.contactUs,
                  drawerCtrl: drawerCtrl,
                ),
                _buildMenuRouteItem(
                  icon: Assets.icons.terms,
                  title: 'Terms & Conditions',
                  route: AppRoutes.termsAndConditions,
                  drawerCtrl: drawerCtrl,
                ),
                _buildMenuRouteItem(
                  icon: Assets.icons.privacy,
                  title: 'Privacy Policy',
                  route: AppRoutes.privacyPolicy,
                  drawerCtrl: drawerCtrl,
                ),
                Obx(() {
                  final connectionController = Get.find<ConnectionController>();
                  final isConnected =
                      connectionController.currentState.value ==
                      HologramState.connected;
                  return _buildMenuItem(
                    icon: Icons.sync,
                    title: 'Sync All',
                    onTap: !isConnected
                        ? () {
                            drawerCtrl.closeDrawer();
                            _handleSyncAll(context);
                          }
                        : null,
                    enabled: !isConnected,
                  );
                }),
                Obx(() {
                  final connectionController = Get.find<ConnectionController>();
                  final isConnected =
                      connectionController.currentState.value ==
                      HologramState.connected;
                  return _buildMenuItem(
                    icon: Icons.cloud_upload,
                    title: 'Upload All to Hologram',
                    onTap: isConnected
                        ? () {
                            drawerCtrl.closeDrawer();
                            _handleUploadAll(context);
                          }
                        : null,
                    enabled: isConnected,
                  );
                }),
                _buildMenuItem(
                  icon: Assets.icons.logout,
                  title: 'Logout',
                  onTap: () {
                    drawerCtrl.closeDrawer();
                    _showLogoutConfirmationDialog(context, authCtrl);
                  },
                ),
              ],
            ),
          ),
          // Version text at the bottom
          Spacer(flex: 1,),
          Padding(
            padding: const EdgeInsets.only(bottom: 48.0),
            child: Center(
              child: Text(
                'Version 1.1.0',
                style: AppFont.w400.s12.copyWith(
                  color: AppColors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRouteItem({
    required String icon,
    required String title,
    required String route,
    required DrawerCtrl.DrawerController drawerCtrl,
  }) {
    return _buildMenuItem(
      icon: icon,
      title: title,
      onTap: () => _navigateToRoute(drawerCtrl, route),
    );
  }

  Widget _buildMenuItem({
    required dynamic icon,
    required String title,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final isIconData = icon is IconData;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: isIconData
                    ? Icon(icon, color: AppColors.white, size: 20)
                    : CustomImageView(
                        imagePath: icon,
                        color: AppColors.white,
                        width: 20,
                        height: 20,
                      ),
              ),
              12.wS,
              Text(title, style: AppFont.w700.s16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToRoute(
    DrawerCtrl.DrawerController drawerCtrl,
    String route,
  ) async {
    drawerCtrl.closeDrawer();
    await Get.toNamed(route);
    drawerCtrl.openDrawer();
  }

  void _showLogoutConfirmationDialog(
    BuildContext context,
    AuthController authController,
  ) {
    CustomGlassConfirmationDialog.show(
      context: context,
      message: 'Are you sure want to logout?',
      yesText: 'Yes',
      noText: 'No',
      onYes: () {
        authController.logout();
      },
      onNo: () {
        Get.back();
      },
    );
  }

  void _handleSyncAll(BuildContext context) {
    if (!Get.isRegistered<SyncController>()) {
      SyncBinding().dependencies();
    }
    if (!Get.isRegistered<SyncController>()) {
      return;
    }

    final syncController = Get.find<SyncController>();
    if (syncController.isSyncing) {
      Get.snackbar('Sync in Progress', 'Sync is already in progress');
      return;
    }

    CustomGlassConfirmationDialog.show(
      context: context,
      message: 'This will sync all data from the server. Continue?',
      yesText: 'Yes',
      noText: 'No',
      onYes: () async {
        Get.back();
        // Show blocking dialog for Phase 1
        SyncProgressDialog.show(
          context: context,
          syncController: syncController,
          allowCancel: true,
        );

        try {
          await syncController.syncAll(
            showDialog: false,
            onBlockingComplete: () {
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pop(); // close blocking dialog after categories
              }
            },
          );
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          Get.snackbar('Error', 'Sync failed: ${e.toString()}');
        }
      },
      onNo: () {
        Get.back();
      },
    );
  }

  void _handleUploadAll(BuildContext context) {
    if (!Get.isRegistered<HologramController>()) {
      Get.snackbar('Error', 'Hologram controller not available');
      return;
    }

    final hologramController = Get.find<HologramController>();
    final connectionController = Get.find<ConnectionController>();

    if (connectionController.currentState.value != HologramState.connected) {
      Get.snackbar('Error', 'Hologram device not connected');
      return;
    }

    CustomGlassConfirmationDialog.show(
      context: context,
      message:
          'This will upload all media files to the hologram device. Continue?',
      yesText: 'Yes',
      noText: 'No',
      onYes: () async {
        Get.back();
        // Implement upload all logic
        try {
          await hologramController.uploadAllMediaToHologram();
          // Progress will be shown in the progress bar on home screen
        } catch (e) {
          AppUtils.showGetSnackbar('Error', 'Upload failed: ${e.toString()}');
        }
      },
      onNo: () {
        Get.back();
      },
    );
  }
}
