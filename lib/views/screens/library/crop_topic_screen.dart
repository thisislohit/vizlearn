import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/data/models/library_model.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_app_bar.dart';
import 'package:vizlearn/views/widgets/custom_elevated_button.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:video_player/video_player.dart';
import 'controllers/crop_topic_controller.dart';

class CropTopicScreen extends StatelessWidget {
  final TopicItem topic;
  final bool hasVideo;
  final bool hasImage;
  final String previewImagePath;

  const CropTopicScreen({
    super.key,
    required this.topic,
    required this.hasVideo,
    required this.hasImage,
    required this.previewImagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(
      CropTopicController(
        topic: topic,
        hasVideo: hasVideo,
        hasImage: hasImage,
        previewImagePath: previewImagePath,
      ),
      tag: topic.id, // Use topic id as tag to ensure unique instance per topic
    );

    if (previewImagePath.isEmpty) {
      // No preview at all – show a simple info screen.
      return CustomWrapper(
        child: Column(
          children: [
            const CustomAppBar(title: 'Crop & Preview'),
            Expanded(
              child: Center(
                child: Text(
                  'No preview available for this topic.',
                  style: AppFont.w600.s14.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CustomWrapper(
      child: Column(
        children: [
          Obx(
            () => CustomAppBar(
              title: 'Crop & Preview',
              leadingBack: true,
              actions: [
                if (!controller.isUploading.value)
                  TextButton(
                    onPressed: controller.resetCrop,
                    child: Text(
                      'Reset',
                      style: AppFont.w600.s14.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md,
              ),
              child: Column(
                children: [
                  Text(
                    topic.topicName,
                    style: AppFont.w700.s18.copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                  8.hS,
                  Text(
                    hasVideo
                        ? 'Pinch and drag to adjust how this video will appear on the hologram.'
                        : 'Pinch and drag to adjust how this image will appear on the hologram.',
                    textAlign: TextAlign.center,
                    style: AppFont.w500.s12.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  24.hS,
                  // Square frame with circular hologram window touching all edges
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: Colors.transparent,
                                child: InteractiveViewer(
                                  transformationController:
                                      controller.transformController,
                                  minScale: 0.2,
                                  maxScale: 3.0,
                                  boundaryMargin: const EdgeInsets.all(200),
                                  clipBehavior: Clip.none,
                                  child: Container(
                                    color: Colors.transparent,
                                    alignment: Alignment.center,
                                    child: Obx(() {
                                      if (hasVideo &&
                                          controller
                                              .isVideoInitialized
                                              .value) {
                                        return AspectRatio(
                                          aspectRatio: controller
                                              .videoPlayerController!
                                              .value
                                              .aspectRatio,
                                          child: VideoPlayer(
                                            controller.videoPlayerController!,
                                          ),
                                        );
                                      }
                                      return CustomImageView(
                                        imagePath: previewImagePath,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                            // Circular hologram viewport touching the square edges.
                            IgnorePointer(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final size =
                                      constraints.biggest.shortestSide;
                                  // Only set viewport side if valid (greater than 0)
                                  if (size > 0) {
                                    controller.setViewportSide(size);
                                  }
                                  // Make hologram circle a bit smaller than the square frame
                                  // so the full square image can be shrunk to fit inside it.
                                  final diameter = size > 0
                                      ? (size * 0.7).toDouble()
                                      : 0.0;
                                  return Center(
                                    child: Container(
                                      width: diameter,
                                      height: diameter,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                            0.9,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  24.hS,
                  Obx(
                    () => CustomElevatedButton(
                      text: controller.isUploading.value
                          ? 'Uploading...'
                          : 'Upload to Hologram',
                      width: double.infinity,
                      height: 48,
                      isDisabled: controller.isUploading.value,
                      onPressed: controller.isUploading.value
                          ? null
                          : controller.uploadToHologram,
                      leftIcon: controller.isUploading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  12.hS,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
