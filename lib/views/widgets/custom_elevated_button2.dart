import 'package:flutter/material.dart';
import 'package:vizlearn/theme/app_font.dart';

import '../../utils/app_export.dart';
import 'base_button.dart';

class CustomElevatedButton2 extends BaseButton {
  const CustomElevatedButton2({
    super.key,
    this.decoration,
    this.color,
    this.textColor,
    this.leftIcon,
    this.rightIcon,
    super.margin,
    super.onPressed,
    super.buttonStyle,
    super.alignment,
    super.buttonTextStyle,
    super.isDisabled,
    super.height,
    super.width,
    required super.text,
  });

  final BoxDecoration? decoration;

  final Widget? leftIcon;

  final Widget? rightIcon;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: buildElevatedButtonWidget,
          )
        : buildElevatedButtonWidget;
  }

  Widget get buildElevatedButtonWidget => Container(
    height: height ?? 50,
    width: width ?? 142,
    margin: margin,
    decoration: decoration,
    child: ElevatedButton(
      style: CustomButtonStyles.customColorButton(
        color ?? AppColors.buttonPrimary,
      ),
      onPressed: isDisabled ?? false ? null : onPressed ?? () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leftIcon ?? const SizedBox.shrink(),
          leftIcon == null
              ? const SizedBox()
              : const SizedBox(width: AppSizes.spaceSmall),
          Flexible(
            child: Text(
              text,
              style:
                  buttonTextStyle ??
                  AppFont.w700.s16.copyWith(color: AppColors.primary),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
          rightIcon ?? const SizedBox.shrink(),
        ],
      ),
    ),
  );
}
