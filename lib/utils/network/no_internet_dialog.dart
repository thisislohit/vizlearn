import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_settings/app_settings.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';

class NoInternetDialog {
  static bool _isOpen = false; // 👈 track dialog state

  static void show({required VoidCallback onRetry}) {
    if (_isOpen) return; // already open, don't show again
    _isOpen = true;

    Get.dialog(
      AlertDialog(
        title:  Text("No Internet Connection", style: AppFont.w700.s20.copyWith(color: AppColors.primary),),
        content: Text("Please check your internet connection.", style: AppFont.w700.s16.copyWith(color: AppColors.primary),),
        actions: [
          TextButton(
            onPressed: () {
              AppSettings.openAppSettings(type: AppSettingsType.wifi);
            },
            child: Text("Open Settings", style: AppFont.w700.s16.copyWith(color: AppColors.primary),),
          ),
          ElevatedButton(
            onPressed: () {
              if (Get.isDialogOpen!) Get.back(); // close dialog
              onRetry(); // retry API call
            },
            child: Text("Retry", style: AppFont.w700.s16.copyWith(color: AppColors.primary),),
          ),
        ],
      ),
      barrierDismissible: true,
    ).then((_) {
      _isOpen = false; // reset flag when dialog is dismissed
    });
  }
}
