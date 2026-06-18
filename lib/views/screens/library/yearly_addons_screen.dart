import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/controllers/library_controller.dart';
import 'package:vizlearn/data/models/library_model.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/controllers/sync_controller.dart';
import 'package:vizlearn/data/models/sync_progress_model.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/custom_loader.dart';

class YearlyAddonsScreen extends GetView<LibraryController> {
  const YearlyAddonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(title: 'Yearly Addons'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.md),
              child: Obx(() => _buildYearlyCategoriesGrid()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyCategoriesGrid() {
    if (controller.yearlyCategories.isEmpty) {
      return Center(
        child: Text(
          'No yearly addons available',
          style: AppFont.w500.s16.copyWith(color: AppColors.white),
        ),
      );
    }

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
      itemCount: controller.yearlyCategories.length,
      itemBuilder: (context, index) {
        final category = controller.yearlyCategories[index];
        return _buildCategoryCard(category, index);
      },
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
                'categoryType': 'yearly',
              },
            );
          },
          child: Container(
            width: double.maxFinite,
            height: double.maxFinite,
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
                syncController.categorySyncStatus['${category.id}_yearly'] ??
                CategorySyncStatus.notStarted;
            if (syncStatus == CategorySyncStatus.syncing) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withValues(alpha: 0.5),
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
                syncController.categorySyncStatus['${category.id}_yearly'] ??
                CategorySyncStatus.notStarted;
            if (syncStatus == CategorySyncStatus.completed ||
                syncStatus == CategorySyncStatus.syncing) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  syncController.syncCategory(
                    category.id,
                    categoryType: 'yearly',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
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

  // Helper to match LibraryScreen aesthetics
  CategoryDecoration _getCategoryDecoration(int index) {
    // Use the same colors for consistency
    switch (index % 8) {
      case 0:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF90A8FF), Color(0xFF3467B3)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3F8BE3), Color(0xFF2862CB)],
            stops: [0.1193, 0.933],
          ),
        );
      case 1:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9E78E1), Color(0xFF4024A4)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8561C3), Color(0xFF533AAD)],
            stops: [0.1193, 0.933],
          ),
        );
      case 2:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF86EBA7), Color(0xFF34B35E)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF86EBA7), Color(0xFF39B662)],
            stops: [0.1193, 0.933],
          ),
        );
      case 3:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEEC7E), Color(0xFFA9A61D)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEEC7E), Color(0xFFB0AE27)],
            stops: [0.1193, 0.933],
          ),
        );
      case 4:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7BEAE), Color(0xFFB35C34)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7BEAE), Color(0xFFB9653F)],
            stops: [0.1687, 0.8981],
          ),
        );
      case 5:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAA2BF), Color(0xFFB33467)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAA2BF), Color(0xFFB63B6C)],
            stops: [0.1193, 0.933],
          ),
        );
      case 6:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF57C7CD), Color(0xFF14979E)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF57C7CD), Color(0xFF189AA1)],
            stops: [0.1687, 0.8981],
          ),
        );
      case 7:
        return CategoryDecoration(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF99C17A), Color(0xFF3C790D)],
            stops: [0.0424, 0.7725],
          ),
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF99C17A), Color(0xFF4A8F1A)],
            stops: [0.1193, 0.933],
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
