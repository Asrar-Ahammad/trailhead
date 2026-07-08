import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for the Trailhead design system.
/// Three-font system:
///   Display:     Barlow Condensed (bold) — hero stat numbers
///   Body:        Space Grotesk (400/500/600/700) — all general UI text
///   Retro label: Pixelify Sans — nav labels, badges, short punchy UI text
///
/// All numeric displays use [FontFeature.tabularFigures()] to prevent
/// digit jitter during live-update animations.
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Display — Barlow Condensed
  // ---------------------------------------------------------------------------

  /// 56sp bold — hero stat numbers on completion/detail screens
  static TextStyle displayLarge({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// 36sp bold — secondary hero stats
  static TextStyle displayMedium({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// 110sp bold — active run hero distance (oversized for at-a-glance readability)
  static TextStyle displayHero({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 110,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// 48sp bold — active run secondary stats (duration, pace)
  static TextStyle displayStat({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  // ---------------------------------------------------------------------------
  // Body — Space Grotesk
  // ---------------------------------------------------------------------------

  /// 24sp bold — screen titles
  static TextStyle headline({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 18sp semibold — card headers, section labels
  static TextStyle title({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 16sp regular — primary readable text
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
      );

  /// 16sp semibold — button labels
  static TextStyle bodyLargeBold({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 14sp regular — secondary text, timestamps
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      );

  /// 14sp bold — emphasized secondary text
  static TextStyle bodyMediumBold({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 12sp semibold, uppercase, +0.5 letter spacing — stat labels, tags
  static TextStyle label({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      );

  /// 12sp bold, uppercase, +1.5 letter spacing — prominent UI labels (e.g. "RUNNING")
  static TextStyle labelCaps({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: color,
      );

  // ---------------------------------------------------------------------------
  // Retro — Pixelify Sans
  // ---------------------------------------------------------------------------

  /// 12sp, Pixelify Sans, uppercase, +1.0 letter spacing
  /// For nav labels, badge text, achievement callouts — never body/paragraph text
  static TextStyle retroLabel({Color? color}) => GoogleFonts.pixelifySans(
        fontSize: 12,
        letterSpacing: 1.0,
        color: color,
      );

  /// 13sp Pixelify Sans — slightly larger for legibility in chips/streak counters
  static TextStyle retroLabelLarge({Color? color}) => GoogleFonts.pixelifySans(
        fontSize: 13,
        letterSpacing: 0.5,
        color: color,
      );
}
