import 'package:flutter/material.dart';

class PixelContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double pixelSize;
  final Offset shadowOffset;
  final EdgeInsetsGeometry? padding;

  const PixelContainer({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.pixelSize = 4.0,
    this.shadowOffset = const Offset(6, 6),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelPainter(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        pixelSize: pixelSize,
        shadowOffset: shadowOffset,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class _PixelPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double pixelSize;
  final Offset shadowOffset;

  _PixelPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.pixelSize,
    required this.shadowOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw Shadow (if any)
    if (shadowOffset != Offset.zero) {
      paint.color = borderColor;
      _drawPixelRect(canvas, Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, size.width, size.height), paint);
    }

    // Draw Background
    paint.color = backgroundColor;
    _drawPixelRect(canvas, Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw Border
    paint.color = borderColor;
    // Top
    canvas.drawRect(Rect.fromLTWH(pixelSize, 0, size.width - 2 * pixelSize, pixelSize), paint);
    // Bottom
    canvas.drawRect(Rect.fromLTWH(pixelSize, size.height - pixelSize, size.width - 2 * pixelSize, pixelSize), paint);
    // Left
    canvas.drawRect(Rect.fromLTWH(0, pixelSize, pixelSize, size.height - 2 * pixelSize), paint);
    // Right
    canvas.drawRect(Rect.fromLTWH(size.width - pixelSize, pixelSize, pixelSize, size.height - 2 * pixelSize), paint);
  }

  void _drawPixelRect(Canvas canvas, Rect rect, Paint paint) {
    // A filled rect with missing corners (like a plus shape)
    canvas.drawRect(Rect.fromLTWH(rect.left + pixelSize, rect.top, rect.width - 2 * pixelSize, rect.height), paint);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top + pixelSize, rect.width, rect.height - 2 * pixelSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
