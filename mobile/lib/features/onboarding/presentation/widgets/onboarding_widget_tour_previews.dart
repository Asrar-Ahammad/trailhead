import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/widgets/pressable_scale.dart';

Widget onboardingTrackingPreview(AppColors colors) {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxWidth: 340),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'GPS ACTIVE',
                    style: AppTextStyles.labelCaps(color: colors.success),
                  ),
                ),
              ],
            ),
            Icon(PhosphorIcons.personSimpleRun, color: colors.accent, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        // Hero Distance
        Center(
          child: Column(
            children: [
              Text(
                '5.24',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  height: 1.0,
                ),
              ),
              Text(
                'KILOMETERS',
                style: AppTextStyles.labelCaps(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Secondary Stats Grid
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatItem('PACE', '4\'38"', colors),
              Container(width: 1, height: 28, color: colors.border),
              _buildStatItem('TIME', '24:18', colors),
              Container(width: 1, height: 28, color: colors.border),
              _buildStatItem('CADENCE', '174', colors),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatItem(String label, String value, AppColors colors) {
  return Column(
    children: [
      Text(
        value,
        style: GoogleFonts.barlowCondensed(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colors.accent,
        ),
      ),
      Text(
        label,
        style: AppTextStyles.label(
          color: colors.textSecondary,
        ).copyWith(fontSize: 10),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Preview 2: Shoe Rotation Card
// ---------------------------------------------------------------------------
Widget onboardingShoePreview(AppColors colors) {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxWidth: 340),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                PhosphorIcons.sneaker,
                color: colors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Endorphin Speed 3',
                    style: AppTextStyles.title(color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily Trainer & Tempos',
                    style: AppTextStyles.bodyMedium(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'HEALTHY',
              style: AppTextStyles.labelCaps(
                color: colors.success,
              ).copyWith(fontSize: 10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Mileage Bar
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              '342 km logged',
              style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
            ),
            Text(
              '600 km limit',
              style: AppTextStyles.bodyMedium(color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 342 / 600,
            minHeight: 8,
            backgroundColor: colors.surface,
            valueColor: AlwaysStoppedAnimation(colors.accent),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(PhosphorIcons.camera, color: colors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Photo inspection enabled',
                style: AppTextStyles.label(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Preview 3: AI Race Predictor
// ---------------------------------------------------------------------------
Widget onboardingPredictionsPreview(AppColors colors) {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxWidth: 340),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'PROJECTED FINISH TIMES',
              style: AppTextStyles.labelCaps(color: colors.accent),
            ),
            Icon(PhosphorIcons.chartLineUpFill, color: colors.accent, size: 18),
          ],
        ),
        const SizedBox(height: 16),
        _buildRaceTile('5K ROAD RACE', '21:15', '4:15 /km', colors),
        const SizedBox(height: 8),
        _buildRaceTile('10K CLASSIC', '44:30', '4:27 /km', colors),
        const SizedBox(height: 8),
        _buildRaceTile('HALF MARATHON', '1:38:50', '4:41 /km', colors),
      ],
    ),
  );
}

Widget _buildRaceTile(
  String event,
  String time,
  String pace,
  AppColors colors,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.border),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event,
              style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
            ),
            Text(
              pace,
              style: AppTextStyles.label(
                color: colors.textSecondary,
              ).copyWith(fontSize: 11),
            ),
          ],
        ),
        Text(
          time,
          style: GoogleFonts.barlowCondensed(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Preview 4: Permissions / Ready
// ---------------------------------------------------------------------------
Widget onboardingPermissionsPreview(
  AppColors colors, {
  required bool requesting,
  required bool isGranted,
  required VoidCallback onRequest,
}) {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxWidth: 340),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isGranted
                  ? PhosphorIcons.checkCircleFill
                  : PhosphorIcons.shieldCheckBold,
              color: isGranted ? colors.success : colors.accent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isGranted ? 'PERMISSIONS READY' : 'QUICK SETUP',
                style: AppTextStyles.labelCaps(
                  color: isGranted ? colors.success : colors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildPermBullet(
          icon: PhosphorIcons.navigationArrowFill,
          title: 'Location Services',
          desc: 'Map routes & live pace calculation',
          colors: colors,
        ),
        const SizedBox(height: 10),
        _buildPermBullet(
          icon: PhosphorIcons.footprintsFill,
          title: 'Physical Activity',
          desc: 'Step count & cadence metrics',
          colors: colors,
        ),
        const SizedBox(height: 16),
        PressableScale(
          onTap: requesting || isGranted ? null : onRequest,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isGranted
                  ? colors.success.withValues(alpha: 0.15)
                  : colors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGranted ? colors.success : colors.accent,
              ),
            ),
            alignment: Alignment.center,
            child: requesting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  )
                : Text(
                    isGranted
                        ? '✓ PERMISSIONS GRANTED'
                        : 'ENABLE PERMISSIONS NOW',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isGranted ? colors.success : colors.accent,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPermBullet({
  required IconData icon,
  required String title,
  required String desc,
  required AppColors colors,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.accent, size: 14),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMediumBold(color: colors.textPrimary),
            ),
            Text(
              desc,
              style: AppTextStyles.label(
                color: colors.textSecondary,
              ).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}
