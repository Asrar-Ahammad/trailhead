import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.colors,
    required this.badge,
    required this.title,
    required this.description,
    required this.preview,
  });
  final AppColors colors;
  final String badge, title, description;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Visual Interactive Preview Box
          Center(child: preview),

          const SizedBox(height: 20),

          // Badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                badge,
                style: GoogleFonts.pixelifySans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: colors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
