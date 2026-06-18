import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_font.dart';
import '../../utils/app_export.dart';
import '../../controllers/hologram_controller.dart';
import 'custom_elevated_button.dart';

class CustomFactoryResetDialog extends StatefulWidget {
  final HologramController controller;

  const CustomFactoryResetDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show({
    required BuildContext context,
    required HologramController controller,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return CustomFactoryResetDialog(controller: controller);
      },
    );
  }

  @override
  State<CustomFactoryResetDialog> createState() => _CustomFactoryResetDialogState();
}

class _CustomFactoryResetDialogState extends State<CustomFactoryResetDialog> {
  bool _countdownStarted = false;

  @override
  void initState() {
    super.initState();
    // Listen to countdown changes
    ever(widget.controller.factoryResetCountdown, (count) {
      if (count == 0 && widget.controller.isFactoryResetting.value) {
        // Reset completed, close dialog
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  void _startCountdown() {
    setState(() {
      _countdownStarted = true;
    });
    widget.controller.startFactoryReset();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
      ),
      child: SizedBox(
        width: dialogWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(24).copyWith(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.6,
                ),
              ),
              child: Obx(() {
                final countdown = widget.controller.factoryResetCountdown.value;
                final isResetting = widget.controller.isFactoryResetting.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: AppColors.red,
                    ),
                    16.hS,
                    // Title
                    Text(
                      'Factory Reset',
                      style: AppFont.w700.s20.copyWith(
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    8.hS,
                    // Warning Message
                    Text(
                      'This will reset all device settings to factory defaults. This action cannot be undone.',
                      style: AppFont.w500.s14.copyWith(
                        color: Colors.black.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    24.hS,
                    // Countdown Display
                    if (_countdownStarted && isResetting && countdown > 0)
                      Column(
                        children: [
                          Text(
                            'Resetting in:',
                            style: AppFont.w500.s14.copyWith(
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          8.hS,
                          Text(
                            countdown.toString(),
                            style: AppFont.w700.s28.copyWith(
                              color: AppColors.red,
                              fontSize: 48,
                            ),
                          ),
                          24.hS,
                          // Cancel Button
                          CustomElevatedButton2(
                            width: double.infinity,
                            height: 50,
                            text: 'Cancel',
                            onPressed: () {
                              widget.controller.cancelFactoryReset();
                              Navigator.of(context).pop();
                            },
                            color: AppColors.white,
                            buttonTextStyle: AppFont.w700.s16.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      )
                    else
                      // Initial confirmation buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomElevatedButton2(
                            width: 100,
                            height: 50,
                            text: 'Cancel',
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            color: AppColors.white,
                            buttonTextStyle: AppFont.w700.s16.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          12.wS,
                          CustomElevatedButton(
                            width: 100,
                            height: 50,
                            text: 'Confirm',
                            onPressed: _startCountdown,
                          ),
                        ],
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

