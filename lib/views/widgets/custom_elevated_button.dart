import 'package:flutter/material.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/responsive_utils.dart';
import '../../utils/app_export.dart';
import 'base_button.dart';

class CustomElevatedButton extends BaseButton {
  const CustomElevatedButton({
    super.key,
    this.decoration,
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

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: buildElevatedButtonWidget(context),
          )
        : buildElevatedButtonWidget(context);
  }

  Widget buildElevatedButtonWidget(context) => Container(
    height: height ?? 56,
    width: width ?? ResponsiveUtils.buttonWidth(context),
    margin: margin,
    decoration: decoration,
    child: ElevatedButton(
      style: buttonStyle,

      onPressed: isDisabled ?? false ? null : onPressed ?? () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leftIcon ?? const SizedBox.shrink(),
          leftIcon == null
              ? SizedBox()
              : const SizedBox(width: AppSizes.spaceSmall),
          Text(
            text,
            style:
                buttonTextStyle ??
                AppFont.w700.s16.copyWith(color: Colors.black)
          ),

          rightIcon ?? const SizedBox.shrink(),
        ],
      ),
    ),
  );
}
