import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'package:vizlearn/views/widgets/ar_warning_dialog.dart';

import '../../../../controllers/connection_controller.dart';
import 'hologram_device_item.dart';

class HologramStatusCard extends StatelessWidget {
  const HologramStatusCard({super.key, required this.controller});

  final ConnectionController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.currentState.value;
    final isDetecting = state == HologramState.detecting;
    final isConnecting = state == HologramState.connecting;
    final isConnected = state == HologramState.connected;
    final isDeviceFound = state == HologramState.deviceFound;
    final isInitial = state == HologramState.initial;
    final isNotFound = state == HologramState.notFound;
    final bool isTab = Get.size.width > 600;

    return GestureDetector(
      onTap: isInitial || isNotFound ? () => controller.startDetection() : null,
      child: Container(
        height: isTab ? 150 : null,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0099A7), const Color(0xFF9EFAFF)],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF00A8C5), const Color(0xFF67F5FC)],
              stops: const [0.0949, 1.015],
              transform: const GradientRotation(281.46 * 3.14159 / 180),
            ),
          ),
          padding: EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hologram - Ideal For',
                      style: AppFont.w700.s18.copyWith(
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    if (isDetecting) ...[
                      12.hS,
                      Row(
                        children: [
                          Text(
                            'Searching nearby devices',
                            style: AppFont.w400.s12.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          8.wS,
                          CustomImageView(
                            imagePath: Assets.gif.loading.path,
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ] else if (isDeviceFound ||
                        isConnecting ||
                        isConnected) ...[
                      8.hS,
                      controller.foundDevices.length > 1
                          ? _buildMultiDeviceList(
                              isConnecting: isConnecting,
                              isConnected: isConnected,
                            )
                          : _buildSingleDeviceAction(
                              isConnecting: isConnecting,
                              isConnected: isConnected,
                            ),
                    ] else ...[
                      16.hS,
                      Text(
                        'check nearby devices',
                        style: AppFont.w400.s12.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              CustomImageView(
                imagePath: Assets.images.hologramFan.path,
                width: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiDeviceList({
    required bool isConnecting,
    required bool isConnected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${controller.foundDevices.length} devices found',
          style: AppFont.w400.s12.copyWith(color: AppColors.primary),
        ),
        16.hS,
        ...controller.foundDevices
            .map(
              (device) => Padding(
                padding: EdgeInsets.only(bottom: AppSizes.sm),
                child: HologramDeviceItem(
                  controller: controller,
                  device: device,
                  isConnecting: isConnecting,
                  isConnected: isConnected,
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildSingleDeviceAction({
    required bool isConnecting,
    required bool isConnected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.hS,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: Get.size.width * 0.3,
              child: Text(
                controller.hotspotName.value.isEmpty
                    ? 'Hologram Device'
                    : controller.hotspotName.value,
                style: AppFont.w700.s12.copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            12.wS,
            HologramDeviceActionButton(
              controller: controller,
              isConnecting: isConnecting,
              isConnected: isConnected,
            ),
          ],
        ),
      ],
    );
  }
}
