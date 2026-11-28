import 'dart:ui';
import 'package:flutter/material.dart';

class AppBarBackdrop extends StatelessWidget {
  const AppBarBackdrop({super.key});

  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: const SizedBox.expand(),
    ),
  );
}
