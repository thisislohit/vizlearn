import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../utils/app_export.dart';
import '../../utils/responsive_utils.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    this.alignment,
    this.width,
    this.height,
    this.scrollPadding,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.textStyle,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textInputType = TextInputType.text,
    this.maxLines,
    this.hintText,
    this.hintStyle,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
    this.contentPadding,
    this.borderDecoration,
    this.fillColor,
    this.filled = true,
    this.validator,
    this.onFocusChange,
    this.borderColor,
    this.onTap,
    this.disabledBorderColor,
    this.disabledColor,
    this.allowShadow = true,
    this.borderRadius,
    this.inputFormatters,
    this.onSubmit,
    this.autovalidateMode,
  });

  final Alignment? alignment;
  final double? width;
  final double? height;
  final TextEditingController? scrollPadding;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool? autofocus;
  final ValueChanged<String>? onChanged;
  final TextStyle? textStyle;
  final bool? obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  final int? maxLines;
  final String? hintText;
  final TextStyle? hintStyle;
  final Widget? prefix;
  final BoxConstraints? prefixConstraints;
  final Widget? suffix;
  final BoxConstraints? suffixConstraints;
  final EdgeInsets? contentPadding;
  final InputBorder? borderDecoration;
  final Color? fillColor;
  final Color? disabledColor;
  final bool? filled;
  final FormFieldValidator<String>? validator;
  final void Function(bool)? onFocusChange;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? disabledBorderColor;
  final bool allowShadow;
  final BorderRadius? borderRadius;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmit;
  final AutovalidateMode? autovalidateMode;

  @override
  CustomTextFormFieldState createState() => CustomTextFormFieldState();
}

class CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode focusNode1;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    focusNode1 = widget.focusNode ?? FocusNode();

    // Add listener to detect focus change
    focusNode1.addListener(() {
    });
  }

  @override
  void dispose() {
    focusNode1.removeListener(() {}); // Remove listener to avoid memory leaks
    if (widget.focusNode == null) {
      focusNode1
          .dispose(); // Dispose focusNode only if it was created in this widget
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.alignment != null
        ? Align(
            alignment: widget.alignment ?? Alignment.center,
            child: textFormFieldWidget(context),
          )
        : textFormFieldWidget(context);
  }

  Widget textFormFieldWidget(BuildContext context) {
    return SizedBox(
      width: widget.width ?? ResponsiveUtils.buttonWidth(context),
      height: widget.height,
      child: Stack(
        children: [
          TextFormField(
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            controller: widget.controller,
            focusNode: focusNode1,
            autovalidateMode:
                widget.autovalidateMode ?? AutovalidateMode.disabled,
            inputFormatters: widget.inputFormatters,
            onFieldSubmitted: widget.onSubmit,
            onTapOutside: (event) {
              focusNode1.unfocus();
              widget.onFocusChange?.call(false);
            },
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            autofocus: widget.autofocus!,
            style:
                widget.textStyle ??
                CustomTextStyles.b2.copyWith(
                  color: !widget.enabled
                      ? AppColors.darkerGrey
                      : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
            obscureText: widget.obscureText!,
            textInputAction: widget.textInputAction,
            keyboardType: widget.textInputType,
            maxLines: widget.maxLines ?? 1,
            decoration: getDecoration(),
            validator: (value) {
              String? validationResult = widget.validator?.call(value);
              return validationResult;
            },
            onTap: () {
              widget.onFocusChange?.call(true);
              widget.onTap?.call();
            },
            onEditingComplete: () {
              widget.onFocusChange?.call(false);
            },
          ),
          // if (!widget.enabled && showSuffix)
          //   Positioned(
          //     right: 0,
          //     child: IgnorePointer(
          //       ignoring: false,
          //       child: GestureDetector(
          //         onTap: widget.suffix is IconButton
          //             ? (widget.suffix as IconButton).onPressed
          //             : widget.onTap, // fallback
          //         child: widget.suffix!,
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  InputDecoration getDecoration() {
    return InputDecoration(
      hintText: widget.hintText ?? "",
      hintStyle:
          widget.hintStyle ??
          CustomTextStyles.b5.copyWith(color: AppColors.primary),
      prefixIcon: widget.prefix!= null ? Padding(
        padding: EdgeInsetsGeometry.all(8),
        child: widget.prefix,
      ) : widget.prefix,
      prefixIconConstraints: widget.prefixConstraints,
      suffixIcon: widget.suffix,
      suffixIconConstraints: widget.suffixConstraints,
      isDense: true,
      contentPadding:
          widget.contentPadding ??
          const EdgeInsets.symmetric(vertical: 18, horizontal: AppSizes.md),
      fillColor: focusNode1.hasFocus || widget.enabled
          ? widget.fillColor ?? Colors.white.withOpacity(0.46)
          : widget.disabledColor ?? AppColors.grey.withOpacity(0.1),
      filled: widget.filled,
      errorBorder: OutlineInputBorder(
        borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
        borderSide: const BorderSide(color: AppColors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
        borderSide: const BorderSide(color: AppColors.red, width: 1),
      ),
      errorStyle: CustomTextStyles.b6.copyWith(color: Colors.red),
      border:
          widget.borderDecoration ??
          OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
            borderSide: const BorderSide(width: 0.5, color: Colors.white),
          ),
      enabledBorder:
          widget.borderDecoration ??
          OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
            borderSide: BorderSide(
              color: widget.borderColor ??  Colors.white,
              width: 0.5,
            ),
          ),
      focusedBorder:
          widget.borderDecoration ??
          OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
            borderSide: BorderSide(
              color: widget.borderColor ?? Color(0xffbef3f6),
              width: 1.5,
            ),
          ),
    );
  }
}
