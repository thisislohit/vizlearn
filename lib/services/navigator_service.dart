import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';

class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static DateTime? currentBackPressTime;

  static Future<dynamic> pushNamed(String routeName,
      {dynamic arguments}) async {
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  // static Future<bool> goBack(BuildContext context) async {
  //   DateTime now = DateTime.now();
  //   if (navigatorKey.currentState?.canPop() ?? false) {
  //     navigatorKey.currentState?.pop();
  //     return Future.value(false);
  //   } else {
  //     if (currentBackPressTime == null || now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
  //       currentBackPressTime = now;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Press back again to exit'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //       return Future.value(false);
  //     }
  //     return Future.value(true);
  //   }
  // }

  /// Second Level pages navigated to dashboard page(base page of app)
  /// Handles back navigation within the app, including a double-tap to exit feature.
  static Future<bool> goBack(BuildContext context) async {
    DateTime now = DateTime.now();

    if (navigatorKey.currentState?.canPop() ?? false) {
      // Pop the current page if possible
      navigatorKey.currentState?.pop();
      return Future.value(false);
    }
    // Handle double-tap to exit scenario
    if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }


  static Future<dynamic> pushNamedAndRemoveUntil(
      String routeName, {
        bool Function(Route<dynamic>)? routePredicate, // Make it optional
        dynamic arguments,
      }) async {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      routePredicate ?? (route) => false, // Default to remove all routes
      arguments: arguments,
    );
  }


  static Future<dynamic> popAndPushNamed(String routeName,
      {dynamic arguments}) async {
    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }
}
