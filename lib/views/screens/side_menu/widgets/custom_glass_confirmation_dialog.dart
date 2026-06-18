import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/app_font.dart';
import '../../../../utils/app_export.dart';
import '../../../widgets/custom_elevated_button.dart';

class CustomGlassConfirmationDialog extends StatelessWidget {
  final String message;
  final String yesText;
  final String noText;
  final VoidCallback onYes;
  final VoidCallback? onNo;
  final double? barrierOpacity;
  final double? blurSigma;

  const CustomGlassConfirmationDialog({
    super.key,
    required this.message,
    this.yesText = 'Yes',
    this.noText = 'No',
    required this.onYes,
    this.onNo,
    this.barrierOpacity = 0.25,
    this.blurSigma = 20,
  });

  static Future<void> show({
    required BuildContext context,
    required String message,
    String? yesText,
    String? noText,
    required VoidCallback onYes,
    VoidCallback? onNo,
    double? barrierOpacity,
    double? blurSigma,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(barrierOpacity ?? 0.25),
      builder: (BuildContext context) {
        return CustomGlassConfirmationDialog(
          message: message,
          yesText: yesText ?? 'Yes',
          noText: noText ?? 'No',
          onYes: onYes,
          onNo: onNo,
          barrierOpacity: barrierOpacity,
          blurSigma: blurSigma,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
      ),
      child: SizedBox(
        width: dialogWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma ?? 10, sigmaY: blurSigma ?? 10),
            child: Container(
              padding: EdgeInsets.all(24).copyWith(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.6,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message
                  Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Text(
                      message,
                      style: AppFont.w700.s16.copyWith(
                        color: Colors.black.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Buttons
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.sm,
                      AppSizes.md,
                      AppSizes.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomElevatedButton2(
                          width: 100,
                          height: 50,
                          text: noText,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onNo?.call();
                          },
                          color: AppColors.white,
                        ),
                        12.wS,
                        CustomElevatedButton(
                          width: 100,
                          height: 50,
                          text: yesText,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onYes();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

