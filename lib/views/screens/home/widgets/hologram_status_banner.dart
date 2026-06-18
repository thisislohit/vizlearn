import 'package:flutter/material.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';

import '../../../../controllers/connection_controller.dart';

class HologramStatusBanner extends StatelessWidget {
  const HologramStatusBanner({
    super.key,
    required this.controller,
    required this.message,
    this.isError = false,
  });

  final ConnectionController controller;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final lowerMessage = message.toLowerCase();
    final tapAction = isError
        ? (lowerMessage.contains('permission') ||
                  lowerMessage.contains('denied'))
              ? () => controller.openAppSettings()
              : lowerMessage.contains('location')
              ? () => controller.openLocationSettings()
              : null
        : null;

    return GestureDetector(
      onTap: tapAction,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isError
              ? AppColors.white.withOpacity(0.6)
              : AppColors.darkGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError ? AppColors.white : AppColors.darkGreen,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message,
                  style: AppFont.w500.s14.copyWith(
                    color: isError ? AppColors.error : AppColors.darkGreen,
                  ),
                ),
              ),
            ),
            if (tapAction != null) ...[
              8.wS,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.open_in_new, size: 16, color: AppColors.error),
              ),
            ],
            IconButton(
              onPressed: () {
                controller.statusMessage.value = '';
              },
              icon: Icon(Icons.close, color: AppColors.white.withOpacity(0.7),),
            ),
          ],
        ),
      ),
    );
  }
}
