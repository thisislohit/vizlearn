import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/utils/validators.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/custom_text_form_field.dart';
import 'package:vizlearn/views/widgets/custom_elevated_button.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import 'controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return CustomWrapper(
      appBar: CustomAppBar(title: 'Profile'),
      child: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            children: [
              24.hS,
              _buildAvatar(controller)  ,
              4.hS,
              TextButton(
                onPressed: () => controller.showImageSourceDialog(),
                child: Text(
                  'Change Avatar',
                  style: AppFont.w500.s14.copyWith(color: AppColors.white),
                ),
              ),
              24.hS,
              CustomTextFormField(
                controller: controller.schoolNameController,
                hintText: 'School Name',
                textInputType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateText,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  LengthLimitingTextInputFormatter(100),
                ],
              ),
              12.hS,
              CustomTextFormField(
                controller: controller.locationController,
                hintText: 'Location',
                textInputType: TextInputType.streetAddress,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateText,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,-]')),
                  LengthLimitingTextInputFormatter(200),
                ],
              ),
              12.hS,
              CustomTextFormField(
                controller: controller.pinCodeController,
                hintText: 'Pin Code',
                textInputType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pin code is required';
                  }
                  if (value.length != 6) {
                    return 'Pin code must be 6 digits';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              24.hS,
              Obx(() => CustomElevatedButton(
                    text: 'Update',
                    width: 180,
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.updateProfile(),
                    isDisabled: controller.isLoading.value,
                  )),
              if (controller.isLoading.value) ...[
                16.hS,
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ProfileController controller) {
    return Obx(() {
      final avatarFile = controller.selectedAvatarImage.value;
      final avatarPath = controller.avatarPath.value;

      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: ClipOval(
          child: avatarFile != null
              ? Image.file(
                  avatarFile,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CustomImageView(
                      imagePath: Assets.icons.profilePng.path,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    );
                  },
                )
              : CustomImageView(
                  imagePath: avatarPath,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
        ),
      );
    });
  }
}
