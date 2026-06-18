import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

import '../../gen/assets.gen.dart';

class CustomMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final double? dropdownWidth;
  final double? buttonWidth;
  final List<String> selectedValues;

  const CustomMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.dropdownWidth,
    this.buttonWidth,
    required this.selectedValues,
  }) : super(key: key);

  @override
  _CustomMultiSelectDropdownState createState() =>
      _CustomMultiSelectDropdownState();
}

class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
  bool isDropdownOpened = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;

  @override
  void dispose() {
    _dropdownOverlay?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (isDropdownOpened) {
      _dropdownOverlay?.remove();
      setState(() {
        isDropdownOpened = false;
      });
    } else {
      _dropdownOverlay = _createDropdownOverlay();
      Overlay.of(context).insert(_dropdownOverlay!);
      setState(() {
        isDropdownOpened = true;
      });
    }
  }

  OverlayEntry _createDropdownOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: widget.dropdownWidth ?? size.width,
        left: offset.dx,
        top: offset.dy + size.height,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadiusStyle.border12,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: widget.items.map((item) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      item,
                      style: CustomTextStyles.b2.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      if (!widget.selectedValues.contains(item)) {
                        setState(() {
                          widget.selectedValues.add(item);
                        });
                        widget.onChanged(widget.selectedValues);
                      }
                      _toggleDropdown();
                    },
                  ),
                  if (item != widget.items.last)
                    const Divider(
                      height: 1,
                      color: Colors.grey,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
         // height: 56,
        width: widget.buttonWidth ?? MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusStyle.radius8,
          // border: Border.all(
          //   color: isDropdownOpened ? Colors.black : Colors.grey.shade300,
          // ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 4,
              //offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.selectedValues.map((value) {
                return Chip(
                  label: Text(value, style: const TextStyle(color: AppColors.black),),
                  deleteIcon: CustomImageView(
                    imagePath: Assets.icons.cross,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusStyle.radius8
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  onDeleted: () {
                    setState(() {
                      widget.selectedValues.remove(value);
                    });
                    widget.onChanged(widget.selectedValues);
                  },
                );
              }).toList(),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleDropdown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.selectedValues.isEmpty
                        ? widget.hintText
                        : widget.hintText,
                    style: CustomTextStyles.b4Primary2.copyWith(color: AppColors.darkGrey),
                  ),
                  Icon(
                    isDropdownOpened
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}