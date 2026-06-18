import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/controllers/library_controller.dart';
import 'package:vizlearn/controllers/sync_controller.dart';
import 'package:vizlearn/data/models/library_model.dart';
import 'package:vizlearn/data/models/sync_progress_model.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/routes/app_routes.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'package:vizlearn/views/widgets/custom_loader.dart';

class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryController = Get.find<LibraryController>();

    return Obx(() {
      if (libraryController.isLoadingCategories.value &&
          libraryController.categories.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CustomLoader(),
        );
      }

      if (libraryController.categoriesError.value.isNotEmpty &&
          libraryController.categories.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                'Unable to load categories',
                style: AppFont.w700.s14.copyWith(color: AppColors.white),
              ),
              8.hS,
              CustomElevatedButton2(
                text: 'Retry',
                width: 120,
                color: AppColors.white,
                buttonTextStyle: AppFont.w700.s14.copyWith(
                  color: AppColors.primary,
                ),
                onPressed: () =>
                    libraryController.fetchCategories(forceRefresh: true),
              ),
            ],
          ),
        );
      }

      if (libraryController.categories.isEmpty) {
        return SizedBox(
          height: Get.size.height * 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No categories available yet',
                style: AppFont.w700.s14.copyWith(color: AppColors.white),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoriesGrid(libraryController),
          if (libraryController.isLoadingCategories.value) ...[
            16.hS,
            const CustomLoader(size: 32),
          ],
        ],
      );
    });
  }

  Widget _buildCategoriesGrid(LibraryController controller) {
    final bool isTab = Get.size.width > 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTab ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 160,
      ),
      itemCount:
          controller.categories.length +
          (controller.yearlyCategories.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < controller.categories.length) {
          final category = controller.categories[index];
          return _buildCategoryCard(category, index, controller);
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
        width: double.maxFinite,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: decoration.borderGradient,
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: decoration.backgroundGradient,
          ),
          padding: EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: Assets.icons.yearlyAddon.path,
                width: 75,
                height: 75,
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

  Widget _buildCategoryCard(
    CategoryModel category,
    int index,
    LibraryController controller,
  ) {
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
            width: double.maxFinite,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: decoration.borderGradient,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              width: double.maxFinite,
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
        // Download button: show only when category is NOT fully downloaded
        if (syncController != null)
          Obx(() {
            final syncStatus =
                syncController.categorySyncStatus['${category.id}'] ??
                CategorySyncStatus.notStarted;
            final isCompleted = syncStatus == CategorySyncStatus.completed;
            final isSyncing = syncStatus == CategorySyncStatus.syncing;

            // While syncing, overlay above shows loader; no icon.
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
                  child: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 16,
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
            colors: [const Color(0xFF90A8FF), const Color(0xFF3467B3)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF3F8BE3), const Color(0xFF2862CB)],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 1:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF9E78E1), const Color(0xFF4024A4)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF8561C3), const Color(0xFF533AAD)],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 2:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF86EBA7), const Color(0xFF34B35E)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF86EBA7), const Color(0xFF39B662)],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 3:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFEEEC7E), const Color(0xFFA9A61D)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFEEEC7E), const Color(0xFFB0AE27)],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 4:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF7BEAE), const Color(0xFFB35C34)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF7BEAE), const Color(0xFFB9653F)],
            stops: const [0.1687, 0.8981],
            transform: const GradientRotation(108.62 * 3.14159 / 180),
          ),
        );
      case 5:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFEAA2BF), const Color(0xFFB33467)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFEAA2BF), const Color(0xFFB63B6C)],
            stops: const [0.1193, 0.933],
            transform: const GradientRotation(94.23 * 3.14159 / 180),
          ),
        );
      case 6:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF57C7CD), const Color(0xFF14979E)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF57C7CD), const Color(0xFF189AA1)],
            stops: const [0.1687, 0.8981],
            transform: const GradientRotation(108.62 * 3.14159 / 180),
          ),
        );
      case 7:
        return CategoryDecoration(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF99C17A), const Color(0xFF3C790D)],
            stops: const [0.0424, 0.7725],
            transform: const GradientRotation(325.21 * 3.14159 / 180),
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF99C17A), const Color(0xFF4A8F1A)],
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
