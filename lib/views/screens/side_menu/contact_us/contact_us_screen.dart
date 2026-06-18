import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';

import '../../../../controllers/side_menu/contact_us_controller.dart';
import '../../../../data/models/side_menu/contact_us_model.dart';
import '../../../../theme/app_font.dart';
import '../../../../utils/app_export.dart';
import '../../../../utils/app_utils.dart';
import '../../../widgets/custom_wrapper.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_error_widget.dart';
import '../../../widgets/custom_pull_to_refresh.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ContactUsController>();

    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(title: 'Contact Us'),
          Expanded(
            child: Obx(() {
              final data = controller.contactData.value;
              final hasContent = data != null;
              final showFullLoader = controller.isLoading.value && !hasContent;

              if (showFullLoader) {
                return const CustomLoader(
                  message: 'Fetching contact details...',
                  style: LoaderStyle.helix,
                  showBackground: true,
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return CustomErrorWidget(
                  message: 'contact details not found',
                  onRetry: () => controller.refreshContactUs(),
                );
              }

              if (!hasContent) {
                return Center(
                  child: Text(
                    'No contact information available',
                    style: AppFont.w500.s16,
                  ),
                );
              }

              return CustomPullToRefresh(
                onRefresh: controller.refreshContactUs,
                padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get in Touch – Book a Demo',
                      style: AppFont.w700.s22,
                    ),
                    8.hS,
                    Text(
                      data.description,
                      style: AppFont.w500.s16,
                      textAlign: TextAlign.justify,
                    ),
                    12.hS,
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: CustomImageView(imagePath: Assets.icons.web),
                        ),
                        TextButton(
                          onPressed: () =>
                              AppUtils.launchURL(context, data.websiteLink),
                          child: Text(
                            'www.vizlearn.co.in',
                            style: AppFont.w700.s16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: CustomImageView(imagePath: Assets.icons.mail),
                        ),
                        TextButton(
                          onPressed: () => AppUtils.launchURL(
                            context,
                            'mailto:${data.email}',
                          ),
                          child: Text(
                            'contact@vizlearn.co.in',
                            style: AppFont.w700.s16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: CustomImageView(imagePath: Assets.icons.call),
                        ),
                        TextButton(
                          onPressed: () => AppUtils.launchURL(
                            context,
                            'tel:${data.mobile}',
                          ),
                          child: Text(
                            '+91 90694 37777',
                            style: AppFont.w700.s16,
                          ),
                        ),
                      ],
                    ),
                    24.hS,
                    Text('VizLearn – Where Learning Comes Alive', style: AppFont.w700.s16,),
                    8.hS,
                    Text('Powered by V Depth Technologies Pvt Ltd', style: AppFont.w700.s10,),
                    16.hS
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
