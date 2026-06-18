import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

/// A class that offers pre-defined button styles for customizing button appearance.
class CustomButtonStyles {
  // text button style
  static ButtonStyle get secondaryButton => ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(AppColors.buttonSecondary),
        side: WidgetStateProperty.all<BorderSide>(
          const BorderSide(color: AppColors.buttonSecondary),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  static ButtonStyle customColorButton(Color color) => ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(color),
        side: WidgetStateProperty.all<BorderSide>(
          BorderSide(color: color),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  static ButtonStyle get whiteButton => ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(AppColors.white),
        side: WidgetStateProperty.all<BorderSide>(
          const BorderSide(color: AppColors.white),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  static ButtonStyle get greyButton => ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(AppColors.darkerGrey),
        side: WidgetStateProperty.all<BorderSide>(
          const BorderSide(color: AppColors.darkerGrey),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  static ButtonStyle get roundButton => ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
    side: WidgetStateProperty.all<BorderSide>(
      const BorderSide(color: AppColors.buttonSecondary),
    ),
      );
}
