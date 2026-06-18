import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/custom_bottom_nav_bar.dart';
import 'package:vizlearn/views/widgets/custom_home_app_bar.dart';
import 'package:vizlearn/views/screens/side_menu/side_menu.dart';
import '../../../controllers/connection_controller.dart';
import '../../../views/widgets/sync_progress_bar.dart';
import '../../../controllers/sync_controller.dart';
import '../../../injectors/bindings/sync_binding.dart';
import 'widgets/hologram_status_banner.dart';
import 'widgets/hologram_status_card.dart';
import 'widgets/library_section.dart';
import 'package:vizlearn/views/widgets/ar_warning_dialog.dart';
import 'package:vizlearn/theme/app_font.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static bool _hasShownWarningOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_hasShownWarningOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWarning();
        _hasShownWarningOnce = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showWarning();
    }
  }

  void _showWarning() {
    if (Get.isDialogOpen != true) {
      showARWarningDialog(context: context, onConfirm: () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure sync controller is available so the app-bar progress can render
    if (!Get.isRegistered<SyncController>()) {
      SyncBinding().dependencies();
    }
    // Note: ConnectionController is usually put by SideMenu or bindings.
    // Assuming it is available.
    final controller = Get.find<ConnectionController>();

    return SideMenu(
      child: CustomWrapper(
        bottomNavBar: const CustomBottomNavBar(),
        child: Column(
          children: [
            const CustomHomeAppBar(),
            const SyncProgressBar(),
            Expanded(
              child: Obx(
                () => SingleChildScrollView(
                  padding: EdgeInsets.all(AppSizes.md),
                  child: _buildContent(controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep this as a method reference for the Widget below
  Widget _buildContent(ConnectionController controller) {
    final hasError =
        controller.statusMessage.value.isNotEmpty &&
        (controller.currentState.value == HologramState.initial ||
            controller.currentState.value == HologramState.notFound);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ///HOLOGRAM CONNECTION CARD
        HologramStatusCard(controller: controller),

        ///HOLOGRAM CONNECTION ERROR BANNER
        if (hasError) ...[
          16.hS,
          HologramStatusBanner(
            controller: controller,
            message: controller.statusMessage.value,
            isError: controller.statusMessage.value != '',
          ),
        ],

        ///AR MODE ENTRY
        24.hS,
        _ArModeCard(),

        ///LIBRARY SECTION
        24.hS,
        const LibrarySection(),
      ],
    );
  }
}

/// Standalone AR mode entry card — tapping navigates to mode selection.
class _ArModeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.arModeSelection),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3B2E), Color(0xFF1A5C48)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            16.wS,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('AR Mode', style: AppFont.w700.s16),
                      8.wS,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.buttonPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NEW',
                          style: AppFont.w700.s10.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  6.hS,
                  Text(
                    'Scan markers • See 3D models • Learn with AR',
                    style: AppFont.w400.s12.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
