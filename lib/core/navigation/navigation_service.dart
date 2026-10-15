import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static void navigateToLogin({String? reason}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    if (reason != null && currentContext != null) {
      ScaffoldMessenger.of(currentContext!).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
