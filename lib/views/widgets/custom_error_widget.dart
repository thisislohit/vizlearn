import 'package:flutter/material.dart';
import '../../theme/app_font.dart';
import '../../utils/app_export.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final String? retryButtonText;
  final EdgeInsets? padding;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.retryButtonText,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppFont.w500.s16.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              16.hS,
              CustomElevatedButton(
                width: 100,
                height: 44,
                onPressed: onRetry,
                text: retryButtonText ?? 'Retry',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

