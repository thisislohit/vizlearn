import 'package:flutter/material.dart';
import 'package:vizlearn/utils/constants/colors.dart';

class CustomCheckboxButton extends StatefulWidget {
  const CustomCheckboxButton({
    super.key,
    required this.onChange,
    this.decoration,
    this.alignment,
    this.isRightCheck,
    this.iconSize,
    required this.value,
    this.text,
    this.width,
    this.padding,
    this.textStyle,
    this.textAlignment,
    this.isExpandedText = false,
  });

  final BoxDecoration? decoration;

  final Alignment? alignment;

  final bool? isRightCheck;

  final double? iconSize;

  final bool value;

  final Function(bool) onChange;

  final RichText? text;

  final double? width;

  final EdgeInsetsGeometry? padding;

  final TextStyle? textStyle;

  final TextAlign? textAlignment;

  final bool isExpandedText;

  @override
  State<CustomCheckboxButton> createState() => _CustomCheckboxButtonState();
}

class _CustomCheckboxButtonState extends State<CustomCheckboxButton> {
  @override
  Widget build(BuildContext context) {
    return widget.alignment != null
        ? Align(
            alignment: widget.alignment ?? Alignment.center,
            child: buildCheckBoxWidget,
          )
        : buildCheckBoxWidget;
  }

  Widget get buildCheckBoxWidget => InkWell(
        onTap: () {
          setState(() {
            widget.onChange(widget.value);
          });
        },
        child: Container(
          decoration: widget.decoration,
          width: widget.width,
          child: (widget.isRightCheck ?? false)
              ? rightSideCheckbox
              : leftSideCheckbox,
        ),
      );

  Widget get leftSideCheckbox => Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: checkboxWidget,
          ),
          widget.isExpandedText ? Expanded(child: textWidget) : textWidget,
        ],
      );

  Widget get rightSideCheckbox => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isExpandedText ? Expanded(child: textWidget) : textWidget,
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: checkboxWidget,
          ),
        ],
      );

  Widget get textWidget => widget.text!;

  Widget get checkboxWidget => SizedBox(
        height: widget.iconSize,
        width: widget.iconSize,
        child: Checkbox(
          checkColor: Colors.white,
          fillColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
            return widget.value
                ? AppColors.primary
                : AppColors.white;
          }),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          value: widget.value,
          onChanged: (value) {
            setState(() {
              widget.onChange(value!);
            });
          },
        ),
      );
}
