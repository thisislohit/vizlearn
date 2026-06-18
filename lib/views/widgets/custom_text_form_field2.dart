import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/app_export.dart';

class CustomTextFormField2 extends StatefulWidget {
  const CustomTextFormField2({
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
    this.allowShadow = true,
    this.borderRadius,
    this.inputFormatters,
    this.isMandatory = false, // ✅ Added param
    this.autovalidateMode,
  });

  final Alignment? alignment;
  final double? width;
  final double? height;
  final EdgeInsets? scrollPadding;
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
  final bool? filled;
  final FormFieldValidator<String>? validator;
  final void Function(bool)? onFocusChange;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? disabledBorderColor;
  final bool allowShadow;
  final BorderRadius? borderRadius;
  final List<TextInputFormatter>? inputFormatters;
  final bool isMandatory; // ✅ Added field
  final AutovalidateMode? autovalidateMode;

  @override
  State<CustomTextFormField2> createState() => _CustomTextFormField2State();
}

class _CustomTextFormField2State extends State<CustomTextFormField2> {
  late FocusNode _focusNode;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(() {
      widget.onFocusChange?.call(_focusNode.hasFocus);
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.alignment != null
        ? Align(
      alignment: widget.alignment ?? Alignment.center,
      child: _buildTextFormField(context),
    )
        : _buildTextFormField(context);
  }

  Widget _buildTextFormField(BuildContext context) {
    final showSuffix = widget.suffix != null;

    return SizedBox(
      width: widget.width ??
          (MediaQuery.of(context).size.width < 600
              ? Get.size.width
              : (MediaQuery.of(context).size.width > 600 &&
              MediaQuery.of(context).size.width < 1000)
              ? Get.size.width * 0.8
              : Get.size.width * 0.5),
      height: widget.height,
      child: Stack(
        children: [
          TextFormField(
            scrollPadding: widget.scrollPadding ??
                EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            controller: widget.controller,
            focusNode: _focusNode,
            autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
            inputFormatters: widget.inputFormatters,
            onTapOutside: (_) => _focusNode.unfocus(),
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            autofocus: widget.autofocus!,
            style: widget.textStyle ??
                CustomTextStyles.b2.copyWith(
                  color: !widget.enabled ? AppColors.darkerGrey : AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
            obscureText: widget.obscureText!,
            textInputAction: widget.textInputAction,
            keyboardType: widget.textInputType,
            maxLines: widget.maxLines ?? 1,
            decoration: _getDecoration(),
            validator: (value) {
              String? validationResult = widget.validator?.call(value);
                hasError = validationResult != null;
              return validationResult;
            },
            onTap: widget.onTap,
          ),
          if (!widget.enabled && showSuffix)
            Positioned(
              right: 0,
              child: IgnorePointer(
                ignoring: false,
                child: GestureDetector(
                  onTap: widget.suffix is IconButton
                      ? (widget.suffix as IconButton).onPressed
                      : widget.onTap,
                  child: widget.suffix!,
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _getDecoration() {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: widget.hintText ?? "",
          style: (widget.hintStyle ??
              CustomTextStyles.b5.copyWith(color: AppColors.darkGrey)),
          children: widget.isMandatory
              ? [
            TextSpan(
              text: " *",
              style: CustomTextStyles.b5.copyWith(color: AppColors.red),
            )
          ]
              : [],
        ),
      ),
      prefixIcon: widget.prefix,
      prefixIconConstraints: widget.prefixConstraints,
      suffixIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget.suffix,
      ),
      suffixIconConstraints: widget.suffixConstraints,
      isDense: true,
      contentPadding: widget.contentPadding ??
          const EdgeInsets.symmetric(vertical: 18, horizontal: AppSizes.md),
      fillColor: widget.fillColor ?? Colors.white,
      filled: widget.filled,
      errorBorder: OutlineInputBorder(
        borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
        borderSide: const BorderSide(
          color: AppColors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
        borderSide: const BorderSide(
          color: AppColors.red,
          width: 1,
        ),
      ),
      errorStyle: CustomTextStyles.b6.copyWith(color: Colors.red),
      border: widget.borderDecoration ??
          OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
            borderSide: const BorderSide(
              width: 1,
              color: AppColors.grey,
            ),
          ),
      enabledBorder: widget.borderDecoration ??
          OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
            borderSide: BorderSide(
              color: widget.borderColor ?? AppColors.grey,
              width: 1,
            ),
          ),
      focusedBorder: widget.borderDecoration ??
          OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadiusStyle.border12,
            borderSide: BorderSide(
              color: widget.borderColor ?? AppColors.primary,
              width: 1,
            ),
          ),
    );
  }
}
