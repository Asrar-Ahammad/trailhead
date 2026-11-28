import 'package:flutter/material.dart';

class InsetSheetBody extends StatelessWidget {
  const InsetSheetBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding.add(
        EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      ),
      child: child,
    ),
  );
}
