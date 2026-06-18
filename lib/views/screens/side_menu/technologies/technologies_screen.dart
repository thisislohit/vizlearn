import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_app_bar.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'controllers/technologies_controller.dart';

class TechnologiesScreen extends StatelessWidget {
  const TechnologiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TechnologiesController());
    
    return CustomWrapper(
      child: Column(
        children: [
          const CustomAppBar(title: 'Our Technologies'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'XR Learning at Its Best',
                    style: AppFont.w700.s22.copyWith(color: AppColors.white),
                  ),
                  24.hS,
                  Obx(() => _buildAccordionItem(
                    controller: controller,
                    id: 'hologram',
                    title: 'Hologram Learning',
                    subtitle: 'Magic inside the Classroom',
                    description: 'Our signature hologram projectors bring animated characters, animals, numbers, and lessons to life — floating in 3D right in the classroom. Children interact with them, follow instructions, and actively participate in every session.\n\nFrom alphabet adventures to workout sessions, hologram learning turns everyday lessons into hands-on, movement-based experiences that boost focus and memory retention.',
                  )),
                  16.hS,
                  Obx(() => _buildAccordionItem(
                    controller: controller,
                    id: 'ar',
                    title: 'Augmented Reality (AR)',
                    subtitle: null,
                    description: null,
                  )),
                  16.hS,
                  Obx(() => _buildAccordionItem(
                    controller: controller,
                    id: 'vr',
                    title: 'Virtual Reality (VR)',
                    subtitle: null,
                    description: null,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionItem({
    required TechnologiesController controller,
    required String id,
    required String title,
    String? subtitle,
    String? description,
  }) {
    final isExpanded = controller.isItemExpanded(id);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF5191A9), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.toggleItem(id),
            child: Container(
              padding: EdgeInsets.all(AppSizes.md).copyWith(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFont.w700.s16.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                  12.wS,
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomImageView(
                        imagePath: Assets.icons.arrowDown,
                        height: 20,
                        width: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isExpanded && subtitle != null) ...[
                  8.hS,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: Text(
                      subtitle,
                      style: AppFont.w700.s14
                    ),
                  ),
                  8.hS,
                ],
                isExpanded && description != null
                    ? Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.md,
                    0,
                    AppSizes.md,
                    AppSizes.md,
                  ),
                  child: Text(
                    description,
                    style: AppFont.w500.s12
                  ),
                )
                    : const SizedBox.shrink(),
              ],
            )
          ),
        ],
      ),
    );
  }
}
