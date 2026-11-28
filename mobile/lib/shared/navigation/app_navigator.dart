import 'package:flutter/material.dart';

/// Builds the app's standard page route in one reusable place.
///
/// Keeping page-route construction centralized makes it easy to apply common
/// transitions or route settings consistently across features later.
class AppNavigator {
  const AppNavigator._();

  static Future<T?> push<T>(BuildContext context, Route<T> route) {
    return Navigator.of(context).push<T>(route);
  }

  static Future<T?> replace<T, TO>(
    BuildContext context,
    Route<T> route, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(route, result: result);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  static Future<T?> dialog<T>(
    BuildContext context,
    WidgetBuilder builder, {
    bool barrierDismissible = true,
  }) => showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
  );

  static Future<T?> bottomSheet<T>(
    BuildContext context,
    WidgetBuilder builder, {
    Color? backgroundColor,
    Color? barrierColor,
    ShapeBorder? shape,
    bool isScrollControlled = false,
  }) => showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    shape: shape,
    isScrollControlled: isScrollControlled,
  );

  static MaterialPageRoute<T> materialPageRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute<T>(builder: builder, settings: settings);
  }
}
