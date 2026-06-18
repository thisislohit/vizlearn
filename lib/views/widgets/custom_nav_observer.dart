import 'package:flutter/material.dart';

class CustomNavigatorObserver extends NavigatorObserver {
  VoidCallback? onNavigation;

  void setNavigationCallback(VoidCallback callback) {
    onNavigation = callback;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigation?.call();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigation?.call();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigation?.call();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onNavigation?.call();
  }
}
