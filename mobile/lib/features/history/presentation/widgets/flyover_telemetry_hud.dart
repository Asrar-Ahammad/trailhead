import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../run_tracking/application/run_format_utils.dart';
import '../../domain/flyover_timeline_model.dart';

/// Glassmorphic Telemetry HUD overlay displaying real-time Distance, Pace, Time, and Elevation.
class FlyoverTelemetryHUD extends StatelessWidget {
  final FlyoverSample sample;
  final bool useMiles;
  final bool isVisible;

  const FlyoverTelemetryHUD({
    super.key,
    required this.sample,
    required this.useMiles,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;

    if (!isVisible) return const SizedBox.shrink();

    // Format metrics
    final distanceStr = RunFormatUtils.formatDistance(sample.distanceM, useMiles);
    final unitStr = RunFormatUtils.getUnitStringUpper(useMiles);

    // Pace conversion
    final pacePerKm = sample.paceSPerKm;
    final paceSec = useMiles ? (pacePerKm * 1.60934).round() : pacePerKm.round();
    final pMins = paceSec ~/ 60;
    final pSecs = (paceSec % 60).toString().padLeft(2, '0');
    final paceStr = '$pMins:$pSecs';
    final paceUnit = useMiles ? '/MI' : '/KM';

    // Duration
    final timeStr = RunFormatUtils.formatDuration(sample.elapsedS);

    // Elevation
    final elevationVal = useMiles ? (sample.elevationM * 3.28084).round() : sample.elevationM.round();
    final elevationUnit = useMiles ? 'FT' : 'M';

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: retroColors.surface.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: retroColors.border.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. Distance
                  _buildMetricCell(
                    context: context,
                    icon: PhosphorIcons.path,
                    label: 'DISTANCE',
                    value: distanceStr,
                    unit: unitStr,
                    accentColor: retroColors.accent,
                  ),

                  _buildDivider(retroColors),

                  // 2. Live Pace
                  _buildMetricCell(
                    context: context,
                    icon: PhosphorIcons.gauge,
                    label: 'LIVE PACE',
                    value: paceStr,
                    unit: paceUnit,
                    accentColor: retroColors.accent,
                  ),

                  _buildDivider(retroColors),

                  // 3. Elapsed Time
                  _buildMetricCell(
                    context: context,
                    icon: PhosphorIcons.timer,
                    label: 'TIME',
                    value: timeStr,
                    unit: '',
                    accentColor: retroColors.textPrimary,
                  ),

                  _buildDivider(retroColors),

                  // 4. Altitude
                  _buildMetricCell(
                    context: context,
                    icon: PhosphorIcons.mountains,
                    label: 'ELEVATION',
                    value: '$elevationVal',
                    unit: elevationUnit,
                    accentColor: retroColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Container(
      width: 1,
      height: 36,
      color: colors.border.withValues(alpha: 0.35),
    );
  }

  Widget _buildMetricCell({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    final retroColors = Theme.of(context).extension<AppColors>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: retroColors.textSecondary),
            const SizedBox(width: 4.5),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: retroColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20.5,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: retroColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
