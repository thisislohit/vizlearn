import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/custom_loader.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isTab = Get.width > 600;

    return CustomWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTab ? 500 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      keyboardHeight, // Extra padding to ensure button is above keyboard
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        keyboardHeight +
                        (isTab ? 0 : 100),
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          CustomImageView(
                            imagePath: Assets.images.vizlearnLogo.path,
                            width: isTab ? 300 : Get.size.width * 0.7,
                          ),
                          (isTab ? 48 : 24).hS,
                          Form(
                            key: controller.formKey,
                            child: Column(
                              children: [
                                CustomTextFormField(
                                  controller: controller.emailController,
                                  focusNode: controller.emailFocusNode,
                                  hintText: 'Email address',
                                  textInputType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: controller.validateEmail,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onSubmit: (value) {
                                    FocusScope.of(context).requestFocus(
                                      controller.passwordFocusNode,
                                    );
                                  },
                                ),
                                12.hS,
                                Obx(
                                  () => CustomTextFormField(
                                    controller: controller.passwordController,
                                    focusNode: controller.passwordFocusNode,
                                    hintText: 'Password',
                                    obscureText:
                                        !controller.isPasswordVisible.value,
                                    textInputType:
                                        TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: controller.validatePassword,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    onSubmit: controller.onPasswordSubmitted,
                                    suffix: IconButton(
                                      icon: Icon(
                                        controller.isPasswordVisible.value
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.primary,
                                      ),
                                      onPressed:
                                          controller.togglePasswordVisibility,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          (isTab ? 48 : 24).hS,
                          Obx(
                            () => controller.isLoading.value
                                ? const CustomLoader(
                                    message: 'Signing you in...',
                                    style: LoaderStyle.vortex,
                                    size: 24,
                                    showBackground: true,
                                  )
                                : CustomElevatedButton2(
                                    text: 'Login',
                                    width: isTab ? 200 : Get.size.width * 0.4,
                                    onPressed: controller.login,
                                    isDisabled: !controller.isFormValid.value,
                                  ),
                          ),
                          const Spacer(flex: 1),
                          SizedBox(
                            height: keyboardHeight > 0 ? 0 : 48,
                          ), // Only add bottom spacing when keyboard is closed
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
