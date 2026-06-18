import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

class AppFont {
  AppFont._();

  static const String _fontFamily = 'Comfortaa';

  static TextStyle normal = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.normal,
  );
  static TextStyle bold = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.bold,
  );
  static TextStyle w200 = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w200,
  );
  static TextStyle w400 = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );
  static TextStyle w500 = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
  );
  static TextStyle w600 = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );
  static TextStyle w700 = const TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );
}

extension AppFontSize on TextStyle {
  TextStyle get s8 {
    return copyWith(fontSize: 8, color: Colors.white);
  }

  TextStyle get s9 {
    return copyWith(fontSize: 9, color: Colors.white);
  }

  TextStyle get s10 {
    return copyWith(fontSize: 10, color: Colors.white);
  }

  TextStyle get s11 {
    return copyWith(fontSize: 11, color: Colors.white);
  }

  TextStyle get s12 {
    return copyWith(fontSize: 12, color: Colors.white);
  }

  TextStyle get s13 {
    return copyWith(fontSize: 13, color: Colors.white);
  }

  TextStyle get s14 {
    return copyWith(fontSize: 14, color: Colors.white);
  }

  TextStyle get s15 {
    return copyWith(fontSize: 15, color: Colors.white);
  }

  TextStyle get s16 {
    return copyWith(fontSize: 16, color: Colors.white);
  }

  TextStyle get s18 {
    return copyWith(fontSize: 18, color: Colors.white);
  }

  TextStyle get s20 {
    return copyWith(fontSize: 20, color: Colors.white);
  }

  TextStyle get s22 {
    return copyWith(fontSize: 22, color: Colors.white);
  }

  TextStyle get s24 {
    return copyWith(fontSize: 24, color: Colors.white);
  }

  TextStyle get s26 {
    return copyWith(fontSize: 26, color: Colors.white);
  }

  TextStyle get s28 {
    return copyWith(fontSize: 28, color: Colors.white);
  }

  TextStyle get s50 {
    return copyWith(fontSize: 50, color: Colors.white);
  }

  TextStyle get s30 {
    return copyWith(fontSize: 30, color: Colors.white);
  }

  TextStyle get s36 {
    return copyWith(fontSize: 36, color: Colors.white);
  }

  TextStyle get s40 {
    return copyWith(fontSize: 40, color: Colors.white);
  }

  TextStyle get s80 {
    return copyWith(fontSize: 80, color: Colors.white);
  }
}

extension AppFontColor on TextStyle {
  TextStyle get white {
    return copyWith(color: AppColors.white);
  }

  TextStyle get black {
    return copyWith(color: AppColors.black);
  }

  TextStyle get grey {
    return copyWith(color: AppColors.grey);
  }

  /// Get theme-aware text color based on brightness
  TextStyle themeAware(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return copyWith(
      color: brightness == Brightness.dark ? Colors.white : Colors.black,
    );
  }

  /// Get primary color text
  TextStyle get primary {
    return copyWith(color: AppColors.primary);
  }
}
