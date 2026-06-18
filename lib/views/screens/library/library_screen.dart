import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/controllers/library_controller.dart';
import 'package:vizlearn/data/models/library_model.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/custom_bottom_nav_bar.dart';
import 'package:vizlearn/views/widgets/custom_home_app_bar.dart';
import 'package:vizlearn/views/screens/side_menu/side_menu.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'package:vizlearn/controllers/sync_controller.dart';
import 'package:vizlearn/data/models/sync_progress_model.dart';
import 'package:vizlearn/views/widgets/custom_loader.dart';

class LibraryScreen extends GetView<LibraryController> {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SideMenu(
      child: CustomWrapper(
        bottomNavBar: const CustomBottomNavBar(),
        child: Column(
          children: [
            const CustomHomeAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSizes.md,
                  right: AppSizes.md,
                  bottom: AppSizes.md,
                ),
                child: Obx(() => _buildCategoriesGrid()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 162,
      ),
      itemCount:
          controller.categories.length +
          (controller.yearlyCategories.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < controller.categories.length) {
          final category = controller.categories[index];
          return _buildCategoryCard(category, index);
        } else {
          return _buildYearlyAddonsCard(index);
        }
      },
    );
  }

  Widget _buildYearlyAddonsCard(int index) {
    final decoration = _getCategoryDecoration(index);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.yearlyAddons),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: decoration.borderGradient,
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: decoration.backgroundGradient,
          ),
          padding: EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: Assets
                    .icons
                    .library
                    .path, // Use a specific icon if available
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              16.hS,
              Text(
                'Yearly Addons',
                style: AppFont.w700.s16.copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    final decoration = _getCategoryDecoration(index);
    final syncController = Get.isRegistered<SyncController>()
        ? Get.find<SyncController>()
        : null;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            controller.selectCategory(category);
            Get.toNamed(
              AppRoutes.chapters,
              arguments: {
                'categoryId': category.id,
                'categoryName': category.name,
              },
            );
          },
          child: Container(
            // Outer container for gradient border (2px)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: decoration.borderGradient,
            ),
            padding: const EdgeInsets.all(2), // 2px border width
            child: Container(
              // Inner container with background gradient
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: decoration.backgroundGradient,
              ),
              padding: EdgeInsets.all(AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomImageView(
                    imagePath: (category.image?.isNotEmpty ?? false)
                        ? category.image
                        : Assets.icons.library.path,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  16.hS,
                  Text(
                    category.name,
                    style: AppFont.w700.s16.copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Sync status overlay
        if (syncController != null)
          Obx(() {
            final syncStatus =
                syncController.categorySyncStatus['${category.id}'] ??
                CategorySyncStatus.notStarted;
            final isSyncing = syncStatus == CategorySyncStatus.syncing;

            if (isSyncing) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(child: CustomLoader(size: 32)),
                ),
              );
            }

            return const SizedBox.shrink();
          }),
        // Download button
        if (syncController != null)
          Obx(() {
            final syncStatus =
                syncController.categorySyncStatus['${category.id}'] ??
                CategorySyncStatus.notStarted;
            final isCompleted = syncStatus == CategorySyncStatus.completed;
            final isSyncing = syncStatus == CategorySyncStatus.syncing;

            if (isCompleted || isSyncing) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  syncController.syncCategory(
                    category.id,
                    categoryType: 'normal',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  CategoryDecoration _getCategoryDecoration(int index) {
    switch (index % 8) {
      case 0:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF90A8FF), // #90A8FF at 77.25%
              const Color(0xFF3467B3), // #3467B3 at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3F8BE3), // #3F8BE3 at 93.3%
              const Color(0xFF2862CB), // #2862CB at 11.93%
            ],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 1:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9E78E1), // #9E78E1 at 77.25%
              const Color(0xFF4024A4), // #4024A4 at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8561C3), // #8561C3 at 93.3%
              const Color(0xFF533AAD), // #533AAD at 11.93%
            ],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 2:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF86EBA7), // #86EBA7 at 77.25%
              const Color(0xFF34B35E), // #34B35E at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF86EBA7), // #86EBA7 at 93.3%
              const Color(0xFF39B662), // #39B662 at 11.93%
            ],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 3:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEEEC7E), // #EEEC7E at 77.25%
              const Color(0xFFA9A61D), // #A9A61D at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEEEC7E), // #EEEC7E at 93.3%
              const Color(0xFFB0AE27), // #B0AE27 at 11.93%
            ],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 4:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF7BEAE), // #F7BEAE at 77.25%
              const Color(0xFFB35C34), // #B35C34 at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF7BEAE), // #F7BEAE at 89.81%
              const Color(0xFFB9653F), // #B9653F at 16.87%
            ],
            stops: const [0.1687, 0.8981],
            transform: const GradientRotation(108.62 * 3.14159 / 180),
          ),
        );
      case 5:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEAA2BF), // #EAA2BF at 77.25%
              const Color(0xFFB33467), // #B33467 at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEAA2BF), // #EAA2BF at 93.3%
              const Color(0xFFB63B6C), // #B63B6C at 11.93%
            ],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 6:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF57C7CD), // #57C7CD at 77.25%
              const Color(0xFF14979E), // #14979E at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF57C7CD), // #57C7CD at 89.81%
              const Color(0xFF189AA1), // #189AA1 at 16.87%
            ],
            stops: const [0.1687, 0.8981],
            transform: const GradientRotation(108.62 * 3.14159 / 180),
          ),
        );
      case 7:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF99C17A), // #99C17A at 77.25%
              const Color(0xFF3C790D), // #3C790D at 4.24%
            ],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF99C17A), // #99C17A at 93.3%
              const Color(0xFF4A8F1A), // Darker green for border start (11.93%)
            ],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(85.23 * 3.14159 / 180),
          ),
        );
      default:
        return _getCategoryDecoration(0);
    }
  }
}

class CategoryDecoration {
  final LinearGradient backgroundGradient;
  final LinearGradient borderGradient;

  CategoryDecoration({
    required this.backgroundGradient,
    required this.borderGradient,
  });
}
