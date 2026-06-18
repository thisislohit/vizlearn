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

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TermsController>();

    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(title: 'Terms & Conditions'),
          Expanded(
            child: Obx(() {
              final data = controller.content.value;
              final hasContent = data != null && data.content.isNotEmpty;
              final showFullLoader = controller.isLoading.value && !hasContent;

              if (showFullLoader) {
                return const CustomLoader(
                  message: 'Fetching terms...',
                  style: LoaderStyle.helix,
                  showBackground: true,
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return CustomErrorWidget(
                  message: 'Terms & Conditions not found',
                  onRetry: controller.refreshContent,
                );
              }

              if (!hasContent) {
                return Center(
                  child: Text(
                    'No terms available',
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
