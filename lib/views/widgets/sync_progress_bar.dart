import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sync_controller.dart';
import '../../controllers/hologram_controller.dart';
import '../../theme/app_font.dart';
import '../../utils/app_export.dart';

class SyncProgressBar extends StatefulWidget {
  const SyncProgressBar({super.key});

  @override
  State<SyncProgressBar> createState() => _SyncProgressBarState();
}

class _SyncProgressBarState extends State<SyncProgressBar> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncController>()) {
      // Sync system not initialized in this context
      return const SizedBox.shrink();
    }

    final syncController = Get.find<SyncController>();
    final hologramController = Get.isRegistered<HologramController>()
        ? Get.find<HologramController>()
        : null;

    return Obx(() {
      final isSyncing = syncController.isSyncing;
      final isUploading =
          hologramController != null &&
          hologramController.isUploadingBatch.value;

      if (!isSyncing && !isUploading) {
        return const SizedBox.shrink();
      }

      String phaseName;
      double percentageValue;
      String? currentItemName;

      if (isSyncing) {
        final progress = syncController.syncProgress.value;
        phaseName = progress.phaseName;
        percentageValue = progress.percentage;
        currentItemName = progress.currentItemName;
      } else {
        // Show upload progress
        phaseName = 'Uploading media to Hologram...';
        final total = hologramController!.totalUploadItems.value;
        final completed = hologramController.completedUploadItems.value;
        percentageValue = total > 0
            ? (completed +
                      (hologramController.currentUploadingProgress.value /
                          100.0)) /
                  total
            : 0.0;
        currentItemName = hologramController.currentUploadingTopicName.value;
      }

      final percentageInt = (percentageValue * 100).toInt();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please don\'t close the app until process is completed',
              style: AppFont.w400.s10,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    phaseName,
                    style: AppFont.w600.s12.copyWith(color: AppColors.white),
                  ),
                ),
                Text('$percentageInt%', style: AppFont.w700.s12),
              ],
            ),
            4.hS,
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentageValue,
                backgroundColor: AppColors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
            4.hS,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentItemName != null &&
                    currentItemName.isNotEmpty &&
                    _showDetails)
                  Expanded(
                    child: Text(
                      currentItemName,
                      style: AppFont.w400.s10.copyWith(
                        color: AppColors.white.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (currentItemName != null) ...[
                  if (_showDetails) 8.wS,
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    child: Text(
                      _showDetails ? 'Hide details' : 'View details',
                      style: AppFont.w600.s10.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}
