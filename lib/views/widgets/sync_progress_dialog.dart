import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sync_controller.dart';
import '../../theme/app_font.dart';
import '../../utils/app_export.dart';

class SyncProgressDialog extends StatelessWidget {
  final SyncController syncController;
  final bool allowCancel;

  const SyncProgressDialog({
    super.key,
    required this.syncController,
    this.allowCancel = false,
  });

  static Future<void> show({
    required BuildContext context,
    required SyncController syncController,
    bool allowCancel = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return SyncProgressDialog(
          syncController: syncController,
          allowCancel: allowCancel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Obx(() {
              final progress = syncController.syncProgress.value;
              final percentage = (progress.percentage * 100).toInt();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Syncing Data',
                    style: AppFont.w700.s20.copyWith(color: AppColors.white),
                  ),
                  16.hS,
                  Text(
                    'Please wait while we set up the app for you.',
                    style: AppFont.w600.s14.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  8.hS,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.percentage,
                      backgroundColor: AppColors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  8.hS,
                  Text(
                    '$percentage%',
                    style: AppFont.w700.s16.copyWith(color: AppColors.primary),
                  ),
                  if (allowCancel) ...[
                    16.hS,
                    TextButton(
                      onPressed: () {
                        syncController.cancelSync();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: AppFont.w600.s14.copyWith(color: AppColors.white),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

