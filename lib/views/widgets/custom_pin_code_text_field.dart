// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import '../../utils/app_export.dart';
//
// class CustomPinCodeTextField extends StatelessWidget {
//   const CustomPinCodeTextField({
//     super.key,
//     required this.context,
//     required this.onChanged,
//     required this.onCompleted,
//     this.alignment,
//     this.controller,
//     this.textStyle,
//     this.hintStyle,
//     this.validator,
//     this.borderWith,
//     this.width,
//     this.height,
//     required this.errorAnimationController,
//     this.hasError = false,
//   });
//
//   final Alignment? alignment;
//
//   final BuildContext context;
//
//   final TextEditingController? controller;
//   final StreamController<ErrorAnimationType> errorAnimationController;
//
//   final TextStyle? textStyle;
//
//   final TextStyle? hintStyle;
//
//   final Function(String) onChanged;
//   final Function(String) onCompleted;
//
//   final FormFieldValidator<String>? validator;
//
//   final double? borderWith;
//   final double? height;
//   final double? width;
//   final bool hasError;
//
//   @override
//   Widget build(BuildContext context) {
//     return alignment != null ? Align(alignment: alignment ?? Alignment.center, child: pinCodeTextFieldWidget(context)) : pinCodeTextFieldWidget(context);
//   }
//
//   Widget pinCodeTextFieldWidget(context) {
//     double fieldHeight;
//     double fieldWidth;
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     if (screenWidth < 600) {
//       // 📱 Mobile
//       fieldHeight = 60;
//       fieldWidth = 80;
//     } else if (screenWidth < 1024) {
//       // 📲 Tablet
//       fieldHeight = 80;
//       fieldWidth = 120;
//     } else {
//       // 💻 Desktop/Web
//       fieldHeight = 100;
//       fieldWidth = 140;
//     }
//
//     return PinCodeTextField(
//       errorTextMargin: const EdgeInsets.symmetric(vertical: 0, horizontal: AppSizes.md),
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       autoDisposeControllers: false,
//       appContext: context,
//       controller: controller,
//       length: 4,
//       keyboardType: TextInputType.number,
//       textStyle: textStyle ?? CustomTextStyles.h5.copyWith(color: AppColors.primary),
//       hintStyle: hintStyle,
//       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//       enableActiveFill: true,
//       errorAnimationController: errorAnimationController,
//
//       pinTheme: PinTheme(
//         fieldHeight: height ?? fieldHeight,
//         fieldWidth: width ?? fieldWidth,
//         shape: PinCodeFieldShape.box,
//         borderWidth: borderWith ?? 0.6,
//         borderRadius: BorderRadius.circular(8),
//         inactiveColor: hasError ? AppColors.red : AppColors.grey,
//         activeColor: hasError ? AppColors.red : AppColors.primary,
//         inactiveFillColor: hasError ? AppColors.red.withOpacity(0.2) : AppColors.white,
//         activeFillColor: hasError ? AppColors.red.withOpacity(0.2) : AppColors.white,
//         selectedColor: hasError ? AppColors.red : AppColors.primary,
//         selectedFillColor: hasError ? AppColors.red.withOpacity(0.2) : AppColors.white.withOpacity(0.2),
//         inactiveBorderWidth: 1,
//         errorBorderColor: AppColors.red,
//         errorBorderWidth: borderWith ?? 1,
//       ),
//       onCompleted: (value) => onCompleted(value),
//       onChanged: (value) => onChanged(value),
//       validator: validator,
//     );
//   }
// }
