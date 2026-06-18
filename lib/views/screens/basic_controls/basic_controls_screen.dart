import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';

import '../../../controllers/hologram_controller.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/custom_home_app_bar.dart';
import '../../widgets/custom_switch.dart';
import '../../widgets/custom_wrapper.dart';
import '../../widgets/sync_progress_bar.dart';
import '../side_menu/side_menu.dart';

class BasicControlsScreen extends StatelessWidget {
  const BasicControlsScreen({super.key});

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
                return SingleChildScrollView(
                  padding: EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    ///Device IP
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Device IP', style: AppFont.w700.s14,),
                              Obx(() => Text(controller.deviceIp.value, style: AppFont.w700.s18,)),
                            ],
                          ),
                          Spacer(),
                          CustomElevatedButton(
                            text: 'Disconnect',
                            width: 150,
                            height: 40,
                            onPressed: () => controller.disconnectDevice(),
                          ),
                        ],
                      ),
                    24.hS,

                    ///Device Power
                    Row(
                      children: [
                        Text('Device Power', style: AppFont.w500.s14,),
                        Spacer(),
                        Obx(() => CustomSwitchWithText(
                          value: controller.isDevicePowerOn.value,
                          onChanged: (val) => controller.setDevicePower(val),
                        )),
                      ],
                    ),
                    24.hS,

                    ///Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => CustomElevatedButton2(
                          text: 'Restart',
                          leftIcon: controller.isRestarting.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                )
                              : CustomImageView(imagePath: Assets.icons.restart, color: AppColors.primary,),
                          width: Get.size.width * 0.44,
                          height: 44,
                          color: AppColors.white,
                          onPressed: controller.isRestarting.value ? null : () => controller.restartDevice(),
                        )),
                        10.wS,
                        Obx(() {
                          final isDevicePlaying = controller.isDevicePlaying.value;
                          final isPowerOn = controller.isDevicePowerOn.value;
                          final isBusy = controller.isPlaying.value;
                          final isEnabled = isPowerOn && !isBusy;
                          final buttonText = !isPowerOn
                              ? 'Play (Power Off)'
                              : isDevicePlaying
                                  ? 'Pause'
                                  : 'Play';
                          final iconPath = !isPowerOn
                              ? Assets.icons.play
                              : isDevicePlaying
                                  ? Assets.icons.pause
                                  : Assets.icons.play;
                          return CustomElevatedButton2(
                            text: buttonText,
                            leftIcon: CustomImageView(
                              imagePath: iconPath,
                              color: AppColors.primary,
                            ),
                            width: Get.size.width * 0.44,
                            height: 44,
                            color: !isPowerOn
                                ? AppColors.darkGrey
                                : isDevicePlaying
                                    ? AppColors.buttonPrimary
                                    : AppColors.white,
                            onPressed: isEnabled ? () => controller.togglePlayPause() : null,
                          );
                        }),
                      ],
                    ),
                    24.hS,
                    
                    
                    ///Brightness
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Brightness', style: AppFont.w700.s14,),
                        Obx(() => Text(
                          controller.brightness.value.round().toString(),
                          style: AppFont.w700.s14.copyWith(color: AppColors.white),
                        )),
                      ],
                    ),
                    8.hS,
                    Obx(() => _AnimatedSlider(
                      value: controller.brightness.value,
                      min: 0,
                      max: 15,
                      onChangeEnd: (value) => controller.setBrightness(value),
                    )),
                    16.hS,

                    ///Volume
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Volume', style: AppFont.w700.s14,),
                        Obx(() => Text(
                          controller.volume.value.round().toString(),
                          style: AppFont.w700.s14.copyWith(color: AppColors.white),
                        )),
                      ],
                    ),
                    8.hS,
                    Obx(() => _AnimatedSlider(
                      value: controller.volume.value,
                      min: 0,
                      max: 15,
                      onChangeEnd: (value) => controller.setVolume(value),
                    )),
                    16.hS,

                    ///Play Mode
                    Text('Play Mode', style: AppFont.w700.s14,),
                    8.hS,
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomElevatedButton2(
                          text: 'Sequential\nLoop',
                          color: controller.playMode.value == PlayMode.sequentialLoop ? AppColors.buttonPrimary : AppColors.white,
                          width: Get.size.width * 0.29,
                          buttonTextStyle: AppFont.w700.s12.copyWith(color: AppColors.primary),
                          height: 50,
                          onPressed: () => controller.setPlayMode(PlayMode.sequentialLoop),
                        ),
                        CustomElevatedButton2(
                          text: 'Single Loop',
                          color: controller.playMode.value == PlayMode.singleLoop ? AppColors.buttonPrimary : AppColors.white,
                          width: Get.size.width * 0.29,
                          buttonTextStyle: AppFont.w700.s12.copyWith(color: AppColors.primary),
                          height: 50,
                          onPressed: () => controller.setPlayMode(PlayMode.singleLoop),
                        ),
                        CustomElevatedButton2(
                          text: 'Random Play',
                          color: controller.playMode.value == PlayMode.randomPlay ? AppColors.buttonPrimary : AppColors.white,
                          width: Get.size.width * 0.29,
                          buttonTextStyle: AppFont.w700.s12.copyWith(color: AppColors.primary),
                          height: 50,
                          onPressed: () => controller.setPlayMode(PlayMode.randomPlay),
                        ),
                      ],
                    )),


                    
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
              'Please connect to a hologram device to use these controls.',
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


class _AnimatedSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChangeEnd;
  final double min;
  final double max;

  const _AnimatedSlider({
    required this.value,
    required this.onChangeEnd,
    required this.min,
    required this.max,
  });

  @override
  State<_AnimatedSlider> createState() => _AnimatedSliderState();
}

class _AnimatedSliderState extends State<_AnimatedSlider>
    with SingleTickerProviderStateMixin {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(_AnimatedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.white,
        inactiveTrackColor: AppColors.darkGrey,
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 6,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      child: Slider(
        value: _currentValue.clamp(widget.min, widget.max),
        onChanged: (value) {
          setState(() => _currentValue = value);
        },
        onChangeEnd: widget.onChangeEnd,
        min: widget.min,
        max: widget.max,
      ),
    );
  }
}
