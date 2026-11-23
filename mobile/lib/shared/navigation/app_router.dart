import 'package:flutter/material.dart';

/// Shared page navigation for the Trailhead app.
///
/// Keep route creation and stack changes here so screens use the same
/// transition behavior and can be updated consistently.
abstract final class AppRouter {
  static Future<T?> push<T extends Object?>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_pageRoute<T>(page));
  }

  static Future<T?> replace<T extends Object?>(
    BuildContext context,
    Widget page, {
    Object? result,
  }) {
    return Navigator.of(context).pushReplacement<T, Object?>(
      _pageRoute<T>(page),
      result: result,
    );
  }

  static Future<T?> replaceAll<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      _pageRoute<T>(page),
      (_) => false,
    );
  }

  static void popUntilFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static MaterialPageRoute<T> _pageRoute<T extends Object?>(Widget page) {
    return MaterialPageRoute<T>(builder: (_) => page);
  }
}
