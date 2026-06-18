import 'package:flutter/material.dart';

import '../../utils/app_export.dart';

class CustomPullToRefresh extends StatelessWidget {
  const CustomPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
    this.indicatorColor,
    this.backgroundColor,
    this.strokeWidth = 2.4,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Color? indicatorColor;
  final Color? backgroundColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: indicatorColor ?? AppColors.primary,
      backgroundColor: backgroundColor ?? AppColors.white,
      strokeWidth: strokeWidth,
      displacement: 16,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        controller: controller,
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }
}

