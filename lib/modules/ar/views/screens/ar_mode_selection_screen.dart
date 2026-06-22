import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/extensions/sizedbox_extensions.dart';
import '../../../../theme/app_font.dart';
import '../../../../routes/app_routes.dart';
import '../../../../views/widgets/custom_app_bar.dart';
import '../../../../views/widgets/custom_wrapper.dart';
import '../../../../views/widgets/custom_elevated_button.dart';

class ArModeSelectionScreen extends StatefulWidget {
  const ArModeSelectionScreen({super.key});

  @override
  State<ArModeSelectionScreen> createState() => _ArModeSelectionScreenState();
}

class _ArModeSelectionScreenState extends State<ArModeSelectionScreen> {
  int _selectedModeIndex = 1; // Default to AR Mode

  bool get _isPreLogin {
    final args = Get.arguments;
    if (args is Map) return args['preLogin'] == true;
    return false;
  }

  void _handleProceed() {
    final preLogin = _isPreLogin;
    if (_selectedModeIndex == 0) {
      // Hologram Mode
      if (preLogin) {
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.back();
      }
    } else {
      // AR Mode
      Get.toNamed(AppRoutes.arDownload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preLogin = _isPreLogin;
    return CustomWrapper(
      appBar: preLogin
          ? null
          : CustomAppBar(
              title: 'Choose Mode',
              leadingBack: true,
              onLeadingTap: () => Get.back(),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSizes.xl.hS,
            _buildHeader(),
            AppSizes.xl.hS,
            _buildModeCard(
              context,
              index: 0,
              icon: Icons.view_in_ar_rounded,
              label: 'Hologram Mode',
              description: 'Project 3D models through your hologram device',
              color: Colors.white.withValues(alpha: 0.06),
              isHighlighted: _selectedModeIndex == 0,
              onTap: () => setState(() => _selectedModeIndex = 0),
            ),
            AppSizes.md.hS,
            _buildModeCard(
              context,
              index: 1,
              icon: Icons.camera_alt_rounded,
              label: 'AR Mode',
              description: 'Scan markers and see 3D models come alive!',
              color: Colors.white.withValues(alpha: 0.06),
              isHighlighted: _selectedModeIndex == 1,
              onTap: () => setState(() => _selectedModeIndex = 1),
            ),
            const Spacer(),
            CustomElevatedButton(
              text: 'Continue',
              onPressed: _handleProceed,
            ),
            AppSizes.lg.hS,
            _buildFooterNote(),
            AppSizes.lg.hS,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your\nLearning Mode',
          style: AppFont.w700.s28.copyWith(height: 1.3),
        ),
        AppSizes.sm.hS,
        Text(
          'Select how you want to explore today',
          style: AppFont.w400.s15.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isHighlighted 
              ? AppColors.buttonPrimary.withValues(alpha: 0.1) 
              : color,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          border: Border.all(
            color: isHighlighted
                ? AppColors.buttonPrimary
                : Colors.white.withValues(alpha: 0.15),
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.buttonPrimary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: Icon(
                icon,
                color: isHighlighted ? AppColors.buttonPrimary : Colors.white,
                size: AppSizes.iconLg,
              ),
            ),
            AppSizes.md.wS,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: AppFont.w700.s16),
                      if (index == 1) ...[
                        AppSizes.sm.wS,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.buttonPrimary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusSm,
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: AppFont.w700.s10.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSizes.xs.hS,
                  Text(
                    description,
                    style: AppFont.w400.s13.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            AppSizes.sm.wS,
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isHighlighted
                  ? AppColors.buttonPrimary
                  : Colors.white54,
              size: AppSizes.iconSm2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white54,
            size: AppSizes.iconSm2,
          ),
          AppSizes.sm2.wS,
          Expanded(
            child: Text(
              'AR Mode requires a camera and good lighting for best results.',
              style: AppFont.w400.s12.copyWith(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}
