import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';

class GoalTargetFields extends StatelessWidget {
  const GoalTargetFields({
    super.key,
    required this.metric,
    required this.target,
    required this.onMetricChanged,
    required this.colors,
    this.includeSteps = false,
  });

  final String metric;
  final TextEditingController target;
  final ValueChanged<String> onMetricChanged;
  final AppColors colors;
  final bool includeSteps;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyMedium(color: colors.textPrimary);
    return AdaptiveColumns(
      maxColumns: 2,
      minColumnWidth: 155,
      spacing: 16,
      children: [
        DropdownButtonFormField<String>(
          initialValue: metric,
          isExpanded: true,
          dropdownColor: colors.surfaceRaised,
          style: style,
          items: [
            if (includeSteps)
              const DropdownMenuItem(value: 'steps', child: Text('Steps')),
            const DropdownMenuItem(
              value: 'distance',
              child: Text('Distance (km)'),
            ),
            const DropdownMenuItem(
              value: 'duration',
              child: Text('Duration (min)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onMetricChanged(value);
          },
        ),
        TextField(
          controller: target,
          style: style,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Target',
            labelStyle: AppTextStyles.label(color: colors.textSecondary),
            filled: true,
            fillColor: colors.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
