import 'package:flutter/material.dart';

/// An animated text widget that interpolates a numeric value from 0 to [targetValue]
/// over [duration].
///
/// The [builder] is called on every animation frame with the current interpolated
/// value, allowing the caller to format it (e.g. as distance, pace, or duration).
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.targetValue,
    required this.builder,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.style,
  });

  final double targetValue;
  final Widget Function(BuildContext context, double value, TextStyle? style) builder;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _controller.duration = widget.duration;
      _animation = Tween<double>(begin: 0.0, end: widget.targetValue).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(context, _animation.value, widget.style);
      },
    );
  }
}
