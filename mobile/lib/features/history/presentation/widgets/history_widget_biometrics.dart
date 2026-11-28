import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class HistoryBiometricTile extends StatelessWidget {
  const HistoryBiometricTile(
    this.colors,
    this.icon,
    this.label,
    this.value, {
    super.key,
    this.tooltipMessage,
  });
  final AppColors colors;
  final IconData icon;
  final String label, value;
  final String? tooltipMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.accent, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelCaps(
                    color: colors.textSecondary,
                  ).copyWith(fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tooltipMessage != null) ...[
                const SizedBox(width: 3),
                Tooltip(
                  message: tooltipMessage!,
                  triggerMode: TooltipTriggerMode.tap,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  textStyle: AppTextStyles.bodyMedium(
                    color: colors.textPrimary,
                  ),
                  child: Icon(
                    PhosphorIcons.info,
                    color: colors.textSecondary,
                    size: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
