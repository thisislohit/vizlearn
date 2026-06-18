import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

class CustomDropdownWithRadio extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double? dropdownWidth;
  final double? buttonWidth;
  final String? selectedValue;

  const CustomDropdownWithRadio({
    super.key,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.dropdownWidth,
    this.buttonWidth,
    this.selectedValue,
  });

  @override
  _CustomDropdownWithRadioState createState() =>
      _CustomDropdownWithRadioState();
}

class _CustomDropdownWithRadioState extends State<CustomDropdownWithRadio> {
  String? selectedOption;
  bool isDropdownOpened = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;



  @override
  void initState() {
    super.initState();
    selectedOption = widget.selectedValue;
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _showDropdown();
    } else {
      _closeDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      isDropdownOpened = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      isDropdownOpened = false;
    });
  }

  OverlayEntry _createOverlayEntry() {

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double dropdownHeight = widget.items.length * 56.0 + 20; // Approximate dropdown height

    final double availableSpaceBelow = screenHeight - (offset.dy + renderBox.size.height);
    final double availableSpaceAbove = offset.dy;

    final bool showAbove = availableSpaceBelow < dropdownHeight;

    // Debugging Output
    print("Screen Height: $screenHeight");
    print("Widget Position Y: ${offset.dy}");
    print("Dropdown Height: $dropdownHeight");
    print("Available Space Below: $availableSpaceBelow");
    print("Available Space Above: $availableSpaceAbove");
    print("Dropdown Opens Above: $showAbove");

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        width: widget.dropdownWidth ?? MediaQuery.of(context).size.width - 32,
        top: showAbove
            ? offset.dy - dropdownHeight - 5 // Open Above
            : offset.dy + renderBox.size.height + 5, // Open Below
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: showAbove ? availableSpaceAbove -10
                         : availableSpaceBelow -10,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.items.length, (index) {
                  return Column(
                    children: [
                      _buildMenuItem(widget.items[index]),
                      if (index != widget.items.length - 1) // Add line except for last item
                        const Divider(color: AppColors.darkGrey, height: 1),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      setState(() {
        selectedOption = widget.selectedValue;
      });
    });
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          height: 56,
          width: widget.buttonWidth ?? MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadiusStyle.border12,
            border: Border.all(
              color: isDropdownOpened ? AppColors.primary : Colors.transparent,
              width: 0.6,
            ),
            boxShadow: AppDecoration.shadow1_4,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedOption ?? widget.hintText,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                Icon(
                  isDropdownOpened ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String item) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedOption = item;
        });
        widget.onChanged(selectedOption);
        _closeDropdown(); // Close dropdown after selection
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item, style: const TextStyle(fontSize: 16)),
            Radio<String>(
              value: item,
              groupValue: selectedOption,
              onChanged: (value) {
                setState(() {
                  selectedOption = value;
                });
                widget.onChanged(selectedOption);
                _closeDropdown(); // Close dropdown when radio button is selected
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}