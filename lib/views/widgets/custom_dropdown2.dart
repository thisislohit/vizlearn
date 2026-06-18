import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

class CustomMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final double? dropdownWidth;
  final double? buttonWidth;
  final List<String> selectedValues;

  const CustomMultiSelectDropdown({
    super.key,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.dropdownWidth,
    this.buttonWidth,
    required this.selectedValues,
  });

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
          borderRadius: BorderRadius.circular(12),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: widget.items.map((item) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDropdownOpened ? Colors.black : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
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
                  label: Text(value),
                  deleteIcon: Icon(
                    Icons.clear,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
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
                    style: const TextStyle(fontSize: 16, color: Colors.black),
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
