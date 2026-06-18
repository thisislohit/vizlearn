import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String hintText;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final double? dropdownWidth;
  final double? buttonWidth;
  final T? selectedValue;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? dropdownBackgroundColor;

  const CustomDropdown({
    super.key,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.dropdownWidth,
    this.buttonWidth,
    this.selectedValue,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.dropdownBackgroundColor,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late T? selectedOption;
  bool isDropdownOpened = false;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.white;
    final borderColor =
        widget.borderColor ?? (isDropdownOpened ? AppColors.primary : Colors.grey.shade300);
    final textColor = widget.textColor ?? Colors.black;
    final dropdownBg = widget.dropdownBackgroundColor ?? Colors.white;

    return Container(
      height: 56,
      // If buttonWidth is null, let parent constraints decide the width
      width: widget.buttonWidth,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          isExpanded: true,
          value: selectedOption,
          // 👉 Custom selected item rendering (no divider)
          selectedItemBuilder: (context) {
            return widget.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.toString(),
                      style: CustomTextStyles.b3.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: widget.items.map((item) {
            final isLast = item == widget.items.last;
            return DropdownMenuItem<T>(
              value: item,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      item.toString(),
                      // Dropdown list items always black for readability
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: Colors.grey.shade300),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => selectedOption = value);
            widget.onChanged(value);
          },
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              selectedOption?.toString() ?? widget.hintText,
              style: TextStyle(
                fontSize: 16,
                color: selectedOption != null ? textColor : (widget.textColor ?? AppColors.darkGrey),
              ),
            ),
          ),
          iconStyleData: IconStyleData(
            icon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isDropdownOpened ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: widget.textColor ?? AppColors.darkerGrey,
              ),
            ),
          ),
          onMenuStateChange: (isOpen) {
            setState(() => isDropdownOpened = isOpen);
          },
          dropdownStyleData: DropdownStyleData(
            // Match dropdown width to button when either dropdownWidth or
            // buttonWidth is provided; otherwise let it follow button size.
            width: widget.dropdownWidth ?? widget.buttonWidth,
            maxHeight: 200,
            decoration: BoxDecoration(
              color: dropdownBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.borderColor?.withOpacity(0.6) ?? Colors.white.withOpacity(0.25),
                width: 0.8,
              ),
            ),
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
