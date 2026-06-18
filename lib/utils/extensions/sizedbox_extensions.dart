import 'package:flutter/material.dart';

/// Extension on [num] to create SizedBox widgets with height or width
extension SizedBoxExtension on num {
  /// Creates a SizedBox with the specified height
  /// 
  /// Example:
  /// ```dart
  /// 16.hS  // SizedBox(height: 16)
  /// ```
  SizedBox get hS => SizedBox(height: toDouble());

  /// Creates a SizedBox with the specified width
  /// 
  /// Example:
  /// ```dart
  /// 16.wS  // SizedBox(width: 16)
  /// ```
  SizedBox get wS => SizedBox(width: toDouble());
}

