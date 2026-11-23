import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOCATED MARKER  (static — no animation)
// A clean, minimal two-ring dot that sits on the user's position.
// White outer ring → subtle shadow → solid accent core.
// ─────────────────────────────────────────────────────────────────────────────

class LocatedMarker extends StatelessWidget {
  final Color color;
  const LocatedMarker({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _StaticDotPainter(color: color),
    );
  }
}

class _StaticDotPainter extends CustomPainter {
  final Color color;
  const _StaticDotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Subtle drop shadow
    canvas.drawCircle(
      center + const Offset(0, 1.5),
      size.width * 0.38,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // White outer ring
    canvas.drawCircle(
      center,
      size.width * 0.38,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Accent core
    canvas.drawCircle(
      center,
      size.width * 0.24,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StaticDotPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATING OVERLAY  (full-canvas radar/sonar sweep)
// Used by live_run_map.dart as a Stack overlay while GPS is being acquired.
// ─────────────────────────────────────────────────────────────────────────────

class LocatingOverlay extends StatefulWidget {
  final Color color;
  const LocatingOverlay({super.key, required this.color});

  @override
  State<LocatingOverlay> createState() => _LocatingOverlayState();
}

class _LocatingOverlayState extends State<LocatingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        painter: _RadarPainter(
          sweep: _ctrl.value,
          color: widget.color,
        ),
        child: child,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Draws a radar/sonar sweep on the full canvas:
///   • 4 concentric dotted circles (grid)
///   • A rotating luminous sweep beam
///   • A trailing fade behind the beam
///   • A pulsing center dot
class _RadarPainter extends CustomPainter {
  final double sweep; // 0 → 1
  final Color color;
  const _RadarPainter({required this.sweep, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = (size.shortestSide / 2) * 0.78;
    final angle = sweep * 2 * math.pi - math.pi / 2;

    // ── subtle dark vignette ──────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    // ── concentric dotted rings ───────────────────────────────────────────
    const ringCount = 4;
    const dotCount = 36;
    const dotRadius = 1.3;

    for (int r = 1; r <= ringCount; r++) {
      final ringR = maxR * (r / ringCount);
      final ringAlpha = 0.12 + (r / ringCount) * 0.10;

      final dotPaint = Paint()
        ..color = color.withValues(alpha: ringAlpha)
        ..style = PaintingStyle.fill;

      for (int d = 0; d < dotCount; d++) {
        final a = (d / dotCount) * 2 * math.pi;
        canvas.drawCircle(
          Offset(center.dx + ringR * math.cos(a),
              center.dy + ringR * math.sin(a)),
          dotRadius,
          dotPaint,
        );
      }
    }

    // ── cross-hair lines ──────────────────────────────────────────────────
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy),
        crossPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR),
        crossPaint);

    // ── sweep trail (gradient arc behind the beam) ────────────────────────
    const trailArc = math.pi * 0.6;
    const trailSteps = 18;
    for (int i = 0; i < trailSteps; i++) {
      final t = i / trailSteps;
      final trailAlpha = 0.22 * t * t; // quadratic fade
      final trailAngle = angle - trailArc * (1.0 - t);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxR * 0.55),
        trailAngle - trailArc / trailSteps,
        trailArc / trailSteps,
        true,
        Paint()
          ..color = color.withValues(alpha: trailAlpha)
          ..style = PaintingStyle.fill,
      );
    }

    // ── beam line ─────────────────────────────────────────────────────────
    final beamEnd = Offset(
      center.dx + maxR * math.cos(angle),
      center.dy + maxR * math.sin(angle),
    );

    // Glow behind the line
    canvas.drawLine(
      center,
      beamEnd,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Sharp bright line
    canvas.drawLine(
      center,
      beamEnd,
      Paint()
        ..color = color.withValues(alpha: 0.80)
        ..strokeWidth = 1.5,
    );

    // ── pulsing center dot ────────────────────────────────────────────────
    final pulse = 0.5 + 0.5 * math.sin(sweep * 4 * math.pi);
    canvas.drawCircle(
      center,
      5.0 + 2.5 * pulse,
      Paint()
        ..color = color.withValues(alpha: 0.45 * pulse)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      3.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sweep != sweep || old.color != color;
}
