import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static bool _isNavigatingToLogin = false;

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static void resetLoginRedirectGuard() {
    _isNavigatingToLogin = false;
  }

  static void navigateToLogin({String? reason}) {
    if (_isNavigatingToLogin) return;
    _isNavigatingToLogin = true;

    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    }

    if (reason != null && reason.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = scaffoldMessengerKey.currentState ??
            (currentContext != null ? ScaffoldMessenger.maybeOf(currentContext!) : null);
        messenger?.clearSnackBars();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(reason),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }
}
