import 'package:flutter/material.dart';

/// A custom [ChipMultiselectField] widget that displays a selectable chip with a delete icon.
///
/// This widget is intended to be used in a multi-select field where each selected item
/// is represented as a chip. The chip displays a title and includes a delete icon that
/// triggers an action when pressed.
///
/// The [title] parameter is required and is used as the text inside the chip.
/// The [onDeleted] parameter is required and is the callback function that is executed
/// when the delete icon is pressed.
///
/// Example usage:
/// ```dart
/// ChipMultiselectField(
///   title: 'Selected Item',
///   onDeleted: () {
///     // Handle deletion
///   },
/// )
/// ```
@protected
final class ChipMultiselectField extends StatelessWidget {
  /// The title text displayed inside the chip.
  final String title;

  /// Callback function triggered when the delete icon is pressed.
  final void Function() onDeleted;
  final bool isDisabled;

  /// Creates a [ChipMultiselectField] widget.
  ///
  /// The [title] and [onDeleted] parameters are required.
  const ChipMultiselectField({
    super.key,
    required this.title,
    required this.onDeleted,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      deleteIconBoxConstraints: isDisabled ? BoxConstraints(maxHeight: 0, maxWidth: 0, minHeight: 0, minWidth: 0) : null,
      backgroundColor: Color(0xFFF3E6F2),
      padding: const EdgeInsets.all(7),
      label: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: Colors.transparent,
        ),
      ),
      deleteIcon: isDisabled
          ? SizedBox()
          : Align(
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 15, color: Colors.black),
            ),
      onDeleted: onDeleted,
    );
  }
}
