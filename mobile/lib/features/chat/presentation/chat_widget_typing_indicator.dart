import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final Color color;
  const TypingIndicator({super.key, required this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_controller.value - delay) % 1.0;
        final opacity = value < 0
            ? 0.0
            : (value > 0.5 ? 1.0 - (value - 0.5) * 2 : value * 2);

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColors>()!.surfaceRaised,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildDot(0), _buildDot(1), _buildDot(2)],
      ),
    );
  }
}
