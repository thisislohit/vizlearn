import 'package:flutter/material.dart';
import '../../utils/app_export.dart';
import 'base_button.dart';

class CustomOutlinedButton extends BaseButton {
  const CustomOutlinedButton({super.key,
    this.decoration,
    this.leftIcon,
    this.rightIcon,
    this.bgColor,
    this.textColor,
    this.borderRadius,

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
  final Color? bgColor;
  final Color? textColor;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: buildOutlinedButtonWidget,
          )
        : buildOutlinedButtonWidget;
  }

  Widget get buildOutlinedButtonWidget => Container(
        height: height ?? 56,
        width: width ?? double.maxFinite,
        margin: margin,
        decoration: decoration ??
            BoxDecoration(
              borderRadius: BorderRadiusStyle.radius8,
              color: bgColor ?? AppColors.background1,
            ),
        child: OutlinedButton(
          style: buttonStyle ??
              OutlinedButton.styleFrom(
                side: const BorderSide(color : AppColors.primary, width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius ?? BorderRadiusStyle.border16,
                ),
                padding: const EdgeInsets.all(0),
              ),
          onPressed: isDisabled ?? false ? null : onPressed ?? () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leftIcon != null) ...[
                leftIcon!,
                const SizedBox(width: AppSizes.spaceSmall),
              ],
              Text(
                text,
                style: buttonTextStyle ??
                    CustomTextStyles.b3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500
                    ),
              ),
              if (rightIcon != null) ...[
                const SizedBox(width: AppSizes.spaceSmall),
                rightIcon!,
              ],
            ],
          ),
        ),
      );
}
