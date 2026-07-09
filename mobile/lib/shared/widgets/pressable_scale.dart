import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';

class PressableScale extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  ConsumerState<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends ConsumerState<PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          ref.read(hapticsServiceProvider).lightImpact();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
        }
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
