import 'package:flutter/material.dart';
import 'dart:math';

class AuroraBackground extends StatefulWidget {
  final Color color1;
  final Color color2;
  
  const AuroraBackground({
    super.key, 
    this.color1 = Colors.orange, 
    this.color2 = Colors.deepOrange,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Slower = fewer repaints per second, less GPU load
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates aurora repaints from the rest of the screen
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * pi;
          return CustomPaint(
            painter: _AuroraPainter(
              t: t,
              color1: widget.color1,
              color2: widget.color2,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

/// Draws two soft radial gradient blobs — no BackdropFilter, no heavy blur pass.
class _AuroraPainter extends CustomPainter {
  final double t;
  final Color color1;
  final Color color2;

  _AuroraPainter({required this.t, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    // Blob 1
    final cx1 = size.width * 0.2 + 60 * cos(t);
    final cy1 = -80.0 + 50 * sin(t);
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [color1.withOpacity(0.55), color1.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx1, cy1), radius: 220));
    canvas.drawCircle(Offset(cx1, cy1), 220, paint1);

    // Blob 2
    final cx2 = size.width * 0.8 + 70 * sin(t);
    final cy2 = -60.0 + 60 * cos(t);
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [color2.withOpacity(0.5), color2.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(cx2, cy2), radius: 200));
    canvas.drawCircle(Offset(cx2, cy2), 200, paint2);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
