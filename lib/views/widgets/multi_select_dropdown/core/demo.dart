// class _MultiSelectFieldState<T> extends State<MultiSelectField<T>>
//     with AutomaticKeepAliveClientMixin {
//   // Add a GlobalKey for the input container
//   final GlobalKey _inputContainerKey = GlobalKey();
//   // ... (other existing fields)
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     double currentMenuHeight = widget.menuHeight ?? 300;
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final isKeyboardOpen = View.of(context).viewInsets.bottom > 0;
//       if (_menuController.isOpen) {
//         if (isKeyboardOpen) {
//           _menuController.open(position: Offset(0, -(currentMenuHeight + 7)));
//         } else {
//           // Default behavior when keyboard is not open
//           _adjustMenuPositionAboveInput();
//         }
//       }
//     });
//
//     return RepaintBoundary(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (widget.title != null) widget.title!(_selectedChoice.isEmpty),
//           LayoutBuilder(builder: (context, size) {
//             return MenuAnchor(
//               alignmentOffset: const Offset(0, 5),
//               controller: _menuController,
//               builder: (context, menu, child) {
//                 currentMenuHeight = widget.menuHeightBaseOnContent
//                     ? size.maxHeight
//                     : widget.menuHeight ?? 300;
//
//                 return InkWell(
//                   hoverColor: Colors.transparent,
//                   overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
//                   onTap: () {
//                     if (!menu.isOpen && !widget.isDisabled) menu.open();
//                     WidgetsBinding.instance.addPostFrameCallback((_) {
//                       _scrollToSelectedItem();
//                     });
//                     if (!_focusNodeTextField.hasFocus) {
//                       _focusNodeTextField.requestFocus();
//                     }
//                     _arrowEnableOrNot();
//                   },
//                   onTapDown: (down) {
//                     _textController.clear();
//                     _arrowEnableOrNot();
//                     _onFilteredChoice = widget.data();
//                   },
//                   child: KeyboardListener(
//                     focusNode: _focusNode,
//                     onKeyEvent: (event) {
//                       // ... (existing key event logic)
//                     },
//                     child: Container(
//                       key: _inputContainerKey, // Attach the key here
//                       width: size.maxWidth,
//                       constraints: const BoxConstraints(minHeight: 56),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         border: _menuController.isOpen ? Border.all(color: Colors.purple) : null,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.grey)],
//                       ),
//                       padding: const EdgeInsets.all(5),
//                       margin: const EdgeInsets.only(top: 2),
//                       child: Flex(
//                         direction: Axis.horizontal,
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           // ... (existing children)
//                           if (widget.useTextFilter)
//                             SearchMultiselectField(
//                               focusNodeTextField: _focusNodeTextField,
//                               isMobile: _isMobile,
//                               label: widget.label,
//                               textStyleLabel: widget.textStyleLabel,
//                               onTap: () {
//                                 if (!menu.isOpen && !widget.isDisabled) menu.open();
//                               },
//                               onChange: (value) {
//                                 _textController.text = value;
//                                 if (!menu.isOpen && !widget.isDisabled) {
//                                   _adjustMenuPositionAboveInput();
//                                 }
//                                 _onSelected = false;
//                                 _searchElement(_textController.text);
//                               },
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//               menuChildren: [
//                 // ... (existing menu children)
//               ],
//               style: widget.menuStyle ??
//                   MenuStyle(
//                     elevation: const WidgetStatePropertyAll<double>(5),
//                     visualDensity: VisualDensity.adaptivePlatformDensity,
//                     maximumSize: widget.menuWidthBaseOnContent &&
//                         widget.menuHeightBaseOnContent
//                         ? null
//                         : WidgetStatePropertyAll<Size>(
//                       Size(widget.menuWidth ?? size.maxWidth, currentMenuHeight),
//                     ),
//                   ),
//             );
//           }),
//           if (widget.footer != null) widget.footer!
//         ],
//       ),
//     );
//   }
//
//   // New method to adjust menu position above the input field
//   void _adjustMenuPositionAboveInput() {
//     if (_inputContainerKey.currentContext != null) {
//       final RenderBox renderBox = _inputContainerKey.currentContext!.findRenderObject() as RenderBox;
//       final position = renderBox.localToGlobal(Offset.zero);
//       final inputHeight = renderBox.size.height;
//       final menuHeight = widget.menuHeight ?? 300;
//
//       // Position the menu just above the input field
//       final offset = Offset(0, position.dy - menuHeight - inputHeight - 5);
//       _menuController.open(position: offset);
//     } else {
//       _menuController.open(); // Fallback to default positioning
//     }
//   }
//
// // ... (rest of the existing methods)
// }