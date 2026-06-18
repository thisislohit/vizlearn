import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:get/get.dart';

import '../../../../controllers/side_menu/cms_controller.dart';
import '../../../../theme/app_font.dart';
import '../../../../utils/app_export.dart';
import '../../../widgets/custom_error_widget.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_pull_to_refresh.dart';
import '../../../widgets/custom_wrapper.dart';

class WhyChooseVizlearnScreen extends StatelessWidget {
  const WhyChooseVizlearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WhyChooseController>();

    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(title: 'Why Choose VizLearn'),
          Expanded(
            child: Obx(() {
              final data = controller.content.value;
              final hasContent = data != null && data.content.isNotEmpty;
              final showFullLoader =
                  controller.isLoading.value && !hasContent;

              if (showFullLoader) {
                return const CustomLoader(
                  message: 'Fetching content...',
                  style: LoaderStyle.helix,
                  showBackground: true,
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return CustomErrorWidget(
                  message: 'content not found',
                  onRetry: controller.refreshContent,
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
                  data: data.content,
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
