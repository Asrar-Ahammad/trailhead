import 'dart:ui';
import 'package:flutter/material.dart';

/// A widget that renders a progressive (gradient) blur over the status bar +
/// app bar area.
///
/// **What is progressive blur?**
/// A standard [BackdropFilter] applies a uniform blur everywhere. Progressive
/// blur stacks several blur layers — each with a different sigma — and uses a
/// gradient mask so that each layer is only visible in its own thin band.
/// The result is blur intensity that increases smoothly from 0 at the bottom
/// edge to [maxBlurSigma] at the very top, matching the native iOS nav-bar
/// blur look seen in apps like Strava, Apple Maps, and Arc Browser.
///
/// **Usage** – wrap a [Stack] child above your scroll content:
/// ```dart
/// Stack(
///   children: [
///     YourScrollableContent(),
///     Positioned(
///       top: 0, left: 0, right: 0,
///       child: ProgressiveBlurBar(
///         height: kToolbarHeight + MediaQuery.of(context).padding.top,
///       ),
///     ),
///   ],
/// )
/// ```
class ProgressiveBlurBar extends StatelessWidget {
  const ProgressiveBlurBar({
    super.key,
    required this.height,
    this.maxBlurSigma = 20.0,
    this.layers = 6,
    this.overlayColor,
    this.child,
  });

  /// Total height of the blurred region (status bar + toolbar).
  final double height;

  /// Maximum blur sigma at the very top of the bar. Defaults to 20.
  final double maxBlurSigma;

  /// Number of blur layers stacked. More layers = smoother gradient but more
  /// GPU cost. 5-6 is the sweet spot for mobile.
  final int layers;

  /// Optional tint drawn on top of the blur (e.g. semi-transparent surface).
  final Color? overlayColor;

  /// Optional child widget rendered above the blur (e.g. title + actions row).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Progressive blur layers
          for (int i = 0; i < layers; i++)
            _BlurLayer(
              layerIndex: i,
              totalLayers: layers,
              maxSigma: maxBlurSigma,
            ),

          // Optional colour tint
          if (overlayColor != null)
            DecoratedBox(
              decoration: BoxDecoration(color: overlayColor),
            ),

          // Child content (title, back button, actions…)
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// A single blur band. Each layer covers the full height of the bar but is
/// masked so that it only "shows" blur in the slice corresponding to its index.
///
/// Index 0 → weakest blur, near bottom edge.
/// Index [totalLayers-1] → strongest blur, at the very top.
class _BlurLayer extends StatelessWidget {
  const _BlurLayer({
    required this.layerIndex,
    required this.totalLayers,
    required this.maxSigma,
  });

  final int layerIndex;
  final int totalLayers;
  final double maxSigma;

  @override
  Widget build(BuildContext context) {
    // Exponential curve: blur ramps up faster toward the top.
    final t = (layerIndex + 1) / totalLayers;
    final sigma = maxSigma * t * t; // quadratic ease-in

    // Each layer is visible only in its vertical slice.
    // Slice boundaries (in normalised 0→1 coords, 0 = top, 1 = bottom):
    //   layer 0 covers [1 - 1/n , 1]   (bottom-most, weakest blur)
    //   layer n-1 covers [0, 1/n]       (top-most, strongest blur)
    final sliceHeight = 1.0 / totalLayers;
    final sliceBottom = 1.0 - layerIndex * sliceHeight;
    final sliceTop = sliceBottom - sliceHeight;

    // Feather the edges slightly for a seamless blend between layers.
    const feather = 0.04;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [
                (sliceTop - feather).clamp(0.0, 1.0),
                (sliceTop + feather).clamp(0.0, 1.0),
                (sliceBottom - feather).clamp(0.0, 1.0),
                (sliceBottom + feather).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}
