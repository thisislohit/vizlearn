import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/custom_error_widget.dart';
import 'package:vizlearn/views/widgets/custom_loader.dart';
import 'package:vizlearn/views/widgets/custom_pull_to_refresh.dart';
import '../../../../controllers/side_menu/cms_controller.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override 
  Widget build(BuildContext context) {
    final controller = Get.find<AboutUsController>();

    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(
            title: 'About Us',
          ),
          Expanded(
            child: Obx(() {
              final aboutUsData = controller.content.value;
              final hasContent =
                  aboutUsData != null && aboutUsData.content.isNotEmpty;
              final showFullLoader =
                  controller.isLoading.value && !hasContent;

              if (showFullLoader) {
                return const CustomLoader(
                  message: 'Fetching latest content...',
                  style: LoaderStyle.helix,
                  showBackground: true,
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return CustomErrorWidget(
                  message: 'About us content not found',
                  onRetry: () => controller.refreshContent(),
                );
              }

              if (!hasContent) {
                return Center(
                  child: Text(
                    'No content available',
                    style: AppFont.w500.s16,
                  ),
                );
              }

              return CustomPullToRefresh(
                onRefresh: controller.refreshContent,
                padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: html.Html(
                  data: aboutUsData.content,
                  style: {
                    "body": html.Style(
                      color: AppColors.white,
                      fontSize: html.FontSize(16),
                      fontWeight: FontWeight.w500,
                    ),
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
