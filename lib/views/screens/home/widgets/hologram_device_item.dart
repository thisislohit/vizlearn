import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../../../controllers/connection_controller.dart';

class HologramDeviceItem extends StatelessWidget {
  const HologramDeviceItem({
    super.key,
    required this.controller,
    required this.device,
    required this.isConnecting,
    required this.isConnected,
  });

  final ConnectionController controller;
  final WifiNetwork device;
  final bool isConnecting;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final deviceName = _cleanSsid(device.ssid);
    final isCurrentDevice = controller.hotspotName.value == deviceName;
    final isThisDeviceConnecting = isConnecting && isCurrentDevice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: Get.size.width * 0.35,
          child: Text(
            deviceName.isEmpty ? 'Hologram Device' : deviceName,
            style: AppFont.w500.s12.copyWith(color: AppColors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        12.wS,
        SizedBox(
          width: isThisDeviceConnecting ? 124 : 96,
          height: 28,
          child: ElevatedButton(
            onPressed: isThisDeviceConnecting
                ? null
                : (isConnected && isCurrentDevice
                      ? () => controller.disconnectDevice()
                      : () => controller.connectDevice(device)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              disabledForegroundColor: AppColors.white.withOpacity(0.5),
              padding: EdgeInsets.symmetric(horizontal: AppSizes.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size(0, 28),
            ),
            child: isThisDeviceConnecting
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomImageView(
                        imagePath: Assets.gif.loading.path,
                        width: 8,
                        height: 8,
                      ),
                      4.wS,
                      Text('Connecting', style: AppFont.w700.s10),
                    ],
                  )
                : isConnected && isCurrentDevice
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('Disconnect', style: AppFont.w700.s12)],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('Connect', style: AppFont.w700.s12)],
                  ),
          ),
        ),
      ],
    );
  }

  String _cleanSsid(String? ssid) => (ssid ?? '').replaceAll('"', '').trim();
}

class HologramDeviceActionButton extends StatelessWidget {
  const HologramDeviceActionButton({
    super.key,
    required this.controller,
    required this.isConnecting,
    required this.isConnected,
  });

  final ConnectionController controller;
  final bool isConnecting;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isConnecting ? 124 : 96,
      height: 28,
      child: ElevatedButton(
        onPressed: isConnecting
            ? null
            : (isConnected
                  ? () => controller.disconnectDevice()
                  : () => controller.connectDevice()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          disabledForegroundColor: AppColors.white.withOpacity(0.5),
          padding: EdgeInsets.symmetric(horizontal: AppSizes.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size(0, 28),
        ),
        child: isConnecting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomImageView(
                    imagePath: Assets.gif.loading.path,
                    width: 8,
                    height: 8,
                  ),
                  4.wS,
                  Text('Connecting', style: AppFont.w700.s10),
                ],
              )
            : isConnected
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('Disconnect', style: AppFont.w700.s12)],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('Connect', style: AppFont.w700.s12)],
              ),
      ),
    );
  }
}
