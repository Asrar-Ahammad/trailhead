import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => const CountdownOverlay(),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> with SingleTickerProviderStateMixin {
  int _countdown = 3;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _animationController.forward(from: 0.0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _countdown--;
      });
      if (_countdown > 0) {
         _animationController.forward(from: 0.0);
      } else {
         _timer.cancel();
         AppNavigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                child: Text(
                  _countdown > 0 ? '$_countdown' : 'GO',
                  style: AppTextStyles.headline(color: colors.accent).copyWith(fontSize: 120),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
