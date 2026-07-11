import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';

class DoubleBackToExitWrapper extends StatefulWidget {
  final Widget child;
  
  const DoubleBackToExitWrapper({super.key, required this.child});

  @override
  State<DoubleBackToExitWrapper> createState() => _DoubleBackToExitWrapperState();
}

class _DoubleBackToExitWrapperState extends State<DoubleBackToExitWrapper> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        const maxDuration = Duration(seconds: 2);
        final isWarning = _lastPressedAt == null || now.difference(_lastPressedAt!) > maxDuration;

        if (isWarning) {
          _lastPressedAt = now;
          
          final colors = Theme.of(context).extension<AppColors>()!;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                style: AppTextStyles.bodyMediumBold(color: colors.background),
                textAlign: TextAlign.center,
              ),
              backgroundColor: colors.accent,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return false;
        }

        return true;
      },
      child: widget.child,
    );
  }
}
