import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';

class MediaProgressDialog extends StatelessWidget {
  const MediaProgressDialog({
    super.key,
    required this.topicName,
    required this.progress,
    required this.title,
  });

  final String topicName;
  final double progress;
  final String title;

  static void show({
    required String title,
    required String topicName,
    required RxDouble progress,
  }) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent closing during download
        child: Obx(
          () => MediaProgressDialog(
            topicName: topicName,
            progress: progress.value,
            title: title,
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void close() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppFont.w700.s18.copyWith(color: AppColors.white),
            ),
            12.hS,
            Text(
              topicName,
              style: AppFont.w500.s14.copyWith(color: AppColors.white.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            24.hS,
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.darkGrey,
              color: AppColors.buttonPrimary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            12.hS,
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: AppFont.w700.s16.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

