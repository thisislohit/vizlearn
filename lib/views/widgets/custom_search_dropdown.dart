// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:vizlearn/utils/app_export.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
//
// import '../../gen/assets.gen.dart';
//
// class CustomSearchField<T> extends StatefulWidget {
//   final FutureOr<List<T>> Function(String) fetchItems;
//   final String? hintText;
//   final bool isDisabled;
//   final void Function(T?)? onSelected;
//   final void Function(String)? onChanged;
//   final T? selectedItem;
//   final String Function(T) itemAsString;
//   final List<T>? defaultItems;
//   final TextEditingController? searchController;
//   final Widget? prefix;
//   final bool hidePrefix;
//   final FocusNode? focusNode;
//
//   const CustomSearchField({
//     super.key,
//     required this.fetchItems,
//     this.hintText,
//     this.isDisabled = false,
//     this.onSelected,
//     this.onChanged,
//     this.selectedItem,
//     required this.itemAsString,
//     this.defaultItems,
//     this.searchController,
//     this.prefix,
//     this.hidePrefix = false,
//     this.focusNode,
//   });
//
//   @override
//   CustomSearchFieldState<T> createState() => CustomSearchFieldState<T>();
// }
//
// class CustomSearchFieldState<T> extends State<CustomSearchField<T>> {
//   late TextEditingController searchController;
//   late FocusNode _focusNode;
//   bool isFocused = false;
//
//   @override
//   void initState() {
//     super.initState();
//     searchController = widget.searchController ?? TextEditingController();
//     _focusNode = widget.focusNode ?? FocusNode();
//
//     _focusNode.addListener(() {
//       if (mounted) {
//         setState(() {
//           isFocused = _focusNode.hasFocus;
//         });
//       }
//     });
//
//     searchController.addListener(() {
//       final text = searchController.text;
//       if (text.isEmpty) {
//         widget.onChanged?.call('');
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) setState(() {});
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     if (widget.searchController == null) searchController.dispose();
//     if (widget.focusNode == null) _focusNode.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TypeAheadField<T>(
//       focusNode: widget.focusNode,
//       controller: searchController,
//       suggestionsCallback: (pattern) async {
//         return await widget.fetchItems(pattern);
//       },
//       itemBuilder: (context, T item) {
//         return ListTile(title: Text(widget.itemAsString(item)));
//       },
//       onSelected: (T item) {
//         widget.onSelected?.call(item);
//       },
//       builder: (context, controller, focusNode) {
//         return CustomTextFormField(
//           height: 54,
//           controller: controller,
//           focusNode: focusNode,
//           hintText: widget.hintText,
//           enabled: !widget.isDisabled,
//           prefix: widget.hidePrefix ? null : widget.prefix ?? Padding(padding: const EdgeInsets.all(AppSizes.sm), child: CustomImageView(imagePath: Assets.icons.search, color: AppColors.darkGrey)),
//
//           suffix:
//               searchController.text.isNotEmpty
//                   ? IconButton(
//                     icon: const Icon(Icons.close),
//                     color: AppColors.primary,
//                     onPressed: () {
//                       searchController.clear();
//                       widget.onChanged?.call('');
//                       focusNode.unfocus();
//                       setState(() {}); // Refresh UI to remove the cross button
//                     },
//                   )
//                   : null,
//
//           onChanged: (value) {
//             widget.onChanged?.call(value);
//             setState(() {}); // Update UI to handle no matches case
//           },
//         );
//       },
//       loadingBuilder: (context) => const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
//       errorBuilder: (context, error) => const Padding(padding: EdgeInsets.all(8.0), child: Text('Error loading suggestions!')),
//       emptyBuilder: (context) => const Padding(padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0), child: Text('No items found!')),
//       hideOnLoading: true,
//       hideOnEmpty: true,
//       hideOnError: true,
//       retainOnLoading: false,
//       debounceDuration: const Duration(milliseconds: 300),
//       animationDuration: const Duration(milliseconds: 200),
//       direction: VerticalDirection.down,
//       offset: const Offset(0, 0),
//       listBuilder:
//           (context, children) => ConstrainedBox(
//             constraints: const BoxConstraints(maxHeight: 200),
//             child: ListView.separated(
//               shrinkWrap: true,
//               itemCount: children.length,
//               itemBuilder: (context, index) => children[index],
//               separatorBuilder:
//                   (context, index) => const Divider(
//                     color: Colors.grey, // Customize the color if needed
//                     height: 1, // Adjust the height of the divider
//                     thickness: 1, // Adjust the thickness of the divider
//                   ),
//             ),
//           ),
//     );
//   }
// }
