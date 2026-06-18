import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

import '../../theme/app_decoration.dart';

class CustomRadioButtonTile extends StatefulWidget {
  const CustomRadioButtonTile({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.prefixIconPath,
    this.focusNode,
    this.width,
    this.height = 56.0,
    this.borderRadius = 16.0,
    this.backgroundColor = Colors.white,
    this.shadowColor = Colors.black12,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
  });

  final String label;
  final Object value;
  final Object? groupValue;
  final ValueChanged<Object?> onChanged;
  final String? prefixIconPath;
  final double? width;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color shadowColor;
  final Color selectedColor;
  final Color unselectedColor;
  final FocusNode? focusNode;


  @override
  State<CustomRadioButtonTile> createState() => _CustomRadioButtonTileState();
}

class _CustomRadioButtonTileState extends State<CustomRadioButtonTile> {
  late FocusNode focusNode1;


  @override
  void initState() {
    super.initState();
    focusNode1 = widget.focusNode ?? FocusNode();

    // Add listener to detect focus change
    focusNode1.addListener(() {
      setState(() {});
    });
  }



  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.value == widget.groupValue;

    return GestureDetector(
      onTap: () => widget.onChanged(widget.value),
      child: Container(
        width: widget.width ?? double.maxFinite,
         height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: AppDecoration.shadow1_4

        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if(widget.prefixIconPath != null)
            CustomImageView(imagePath: widget.prefixIconPath,),
            const SizedBox(width: AppSizes.spaceSmall,),
            Text(
              widget.label,
              style:const  TextStyle(
                fontSize: AppSizes.md,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? widget.selectedColor : widget.unselectedColor,
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selectedColor,
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
