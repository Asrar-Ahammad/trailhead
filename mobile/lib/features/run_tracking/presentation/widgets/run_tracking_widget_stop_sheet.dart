import 'package:trailhead_mobile/shared/widgets/inset_sheet_body.dart';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'dart:ui';
import 'package:trailhead_mobile/shared/widgets/pressable_scale.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';

class RunStopSheet extends StatelessWidget {
  const RunStopSheet({required this.colors, required this.activityType});

  final AppColors colors;
  final String activityType;

  @override
  Widget build(BuildContext context) {
    final activityStr = activityType.toLowerCase() == 'walk' ? 'Walk' : 'Run';
    return SafeArea(
      child: InsetSheetBody(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Finish Workout?',
              style: AppTextStyles.headline(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Resume
            PressableScale(
              onTap: () => AppNavigator.pop(context, 'resume'),
              child: _SheetButton(
                label: 'Resume Tracking',
                backgroundColor: colors.surfaceRaised,
                textColor: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Save
            PressableScale(
              onTap: () => AppNavigator.pop(context, 'save'),
              child: _SheetButton(
                label: 'Finish & Save',
                backgroundColor: colors.accent,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Discard
            PressableScale(
              onTap: () => AppNavigator.pop(context, 'discard'),
              child: _SheetButton(
                label: 'Discard $activityStr',
                backgroundColor: Colors.transparent,
                textColor: colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        boxShadow: backgroundColor == Colors.transparent
            ? null
            : [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppTextStyles.bodyLargeBold(color: textColor)),
    );
  }
}
