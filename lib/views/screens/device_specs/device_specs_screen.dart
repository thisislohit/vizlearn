import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/gradient_divider.dart';

import '../../../controllers/hologram_controller.dart';
import '../../../theme/app_font.dart';
import '../../../utils/constants/sizes.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_home_app_bar.dart';
import '../../widgets/custom_wrapper.dart';
import '../../widgets/sync_progress_bar.dart';
import '../side_menu/side_menu.dart';

class DeviceSpecsScreen extends StatelessWidget {
  const DeviceSpecsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HologramController>();
    return SideMenu(
      child: CustomWrapper(
        bottomNavBar: const CustomBottomNavBar(),
        child: Column(
          children: [
            const CustomHomeAppBar(),
            const SyncProgressBar(),
            Expanded(
              child: Obx(() {
                if (!controller.isReady) {
                  return const _ConnectionPrompt();
                }
                final deviceInfo = controller.deviceInfoRx.value;
                final status = controller.deviceStatusRx.value;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Device IP', style: AppFont.w700.s14),
                              Text(
                                controller.deviceIp.value,
                                style: AppFont.w700.s18,
                              ),
                            ],
                          ),
                          const Spacer(),
                          CustomElevatedButton(
                            text: 'Disconnect',
                            width: 150,
                            height: 40,
                            onPressed: () => controller.disconnectDevice(),
                          ),
                        ],
                      ),
                      16.hS,
                      const GradientDivider(),
                      16.hS,
                      _SpecSection(
                        title: 'Device Information',
                        rows: [
                          _SpecData('Device ID', deviceInfo?.id ?? '-'),
                          _SpecData('SN / Name', deviceInfo?.name ?? '-'),
                          _SpecData('Version', deviceInfo?.versionNumber ?? '-'),
                          _SpecData('Device Type', deviceInfo?.deviceType?.toString() ?? '-'),
                          _SpecData('Brand Name', deviceInfo?.brandName ?? '-'),
                          _SpecData('App Name', deviceInfo?.appName ?? '-'),
                          _SpecData('Password', deviceInfo?.password ?? '-'),
                        ],
                      ),
                      24.hS,
                      const GradientDivider(),
                      24.hS,
                      _SpecSection(
                        title: 'Device Status',
                        rows: [
                          _SpecData('Power State', _formatPower(status?.open)),
                          _SpecData(
                            'Brightness',
                            status?.brightness != null ? '${status!.brightness} / 15' : '-',
                          ),
                          _SpecData(
                            'Volume',
                            status?.volume != null ? '${status!.volume} / 15' : '-',
                          ),
                          _SpecData('Play Mode', _formatPlayMode(status?.playMode)),
                          _SpecData('Current File ID', status?.fileId?.toString() ?? '-'),
                          _SpecData(
                            'Wi‑Fi Signal',
                            status?.wifiSignal != null ? '${status!.wifiSignal}%' : '-',
                          ),
                          _SpecData(
                            'Free Space',
                            status?.memory != null ? '${status!.memory} MB' : '-',
                          ),
                          _SpecData('IP Address', status?.ip ?? '-'),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPrompt extends StatelessWidget {
  const _ConnectionPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connect to a hologram device to view specs.',
              style: AppFont.w700.s14.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            16.hS,
            CustomElevatedButton(
              text: 'Go Home',
              width: 160,
              onPressed: () => Get.offAllNamed(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecSection extends StatelessWidget {
  const _SpecSection({required this.title, required this.rows});

  final String title;
  final List<_SpecData> rows;

  @override
  Widget build(BuildContext context) {
    final List<List<_SpecData>> pairs = [];
    for (int i = 0; i < rows.length; i += 2) {
      pairs.add(rows.sublist(i, i + 2 > rows.length ? rows.length : i + 2));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFont.w700.s20,
        ),
        12.hS,
        for (int i = 0; i < pairs.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SpecCell(data: pairs[i][0])),
              16.wS,
              Expanded(
                child: pairs[i].length > 1 ? _SpecCell(data: pairs[i][1]) : const SizedBox.shrink(),
              ),
            ],
          ),
          if (i != pairs.length - 1) 16.hS,
        ],
      ],
    );
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({required this.data});

  final _SpecData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.label,
          style: AppFont.w500.s13.copyWith(color: AppColors.white.withOpacity(0.7)),
        ),
        4.hS,
        Text(
          data.value,
          style: AppFont.w700.s18.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}

class _SpecData {
  const _SpecData(this.label, this.value);

  final String label;
  final String value;
}

String _formatPower(bool? isOn) {
  if (isOn == null) return '-';
  return isOn ? 'ON' : 'OFF';
}

String _formatPlayMode(int? mode) {
  switch (mode) {
    case 1:
      return 'Sequential Loop';
    case 2:
      return 'Single Loop';
    case 3:
      return 'Random Play';
    default:
      return '-';
  }
}
