import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/goals_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SetGoalsSheet extends ConsumerStatefulWidget {
  final AppColors retroColors;
  const SetGoalsSheet({super.key, required this.retroColors});

  @override
  ConsumerState<SetGoalsSheet> createState() => _SetGoalsSheetState();
}

class _SetGoalsSheetState extends ConsumerState<SetGoalsSheet> {
  late String _dailyMetric;
  late double _dailyTarget;
  late String _monthlyMetric;
  late double _monthlyTarget;
  
  final _dCtrl = TextEditingController();
  final _mCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final goals = ref.read(goalsProvider).valueOrNull ?? Goals.empty();
    _dailyMetric = goals.dailyGoalMetric;
    _dailyTarget = goals.dailyGoalTarget;
    _monthlyMetric = goals.monthlyGoalMetric;
    _monthlyTarget = goals.monthlyGoalTarget;
    
    _dCtrl.text = _dailyTarget.toInt().toString();
    _mCtrl.text = _monthlyTarget.toInt().toString();
  }

  @override
  void dispose() {
    _dCtrl.dispose();
    _mCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final dTarget = double.tryParse(_dCtrl.text) ?? 0.0;
    final mTarget = double.tryParse(_mCtrl.text) ?? 0.0;
    
    ref.read(goalsProvider.notifier).saveGoals(Goals(
      dailyGoalMetric: _dailyMetric,
      dailyGoalTarget: dTarget,
      monthlyGoalMetric: _monthlyMetric,
      monthlyGoalTarget: mTarget,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SET GOALS', style: AppTextStyles.title(color: widget.retroColors.textPrimary)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(PhosphorIcons.x(), color: widget.retroColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('DAILY GOAL', style: AppTextStyles.label(color: widget.retroColors.accent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _dailyMetric,
                  dropdownColor: widget.retroColors.surfaceRaised,
                  style: AppTextStyles.bodyMedium(color: widget.retroColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'steps', child: Text('Steps')),
                    DropdownMenuItem(value: 'distance', child: Text('Distance (km)')),
                    DropdownMenuItem(value: 'duration', child: Text('Duration (min)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _dailyMetric = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _dCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMedium(color: widget.retroColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Target',
                    labelStyle: AppTextStyles.label(color: widget.retroColors.textSecondary),
                    filled: true,
                    fillColor: widget.retroColors.surfaceRaised,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('MONTHLY GOAL', style: AppTextStyles.label(color: widget.retroColors.accent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _monthlyMetric,
                  dropdownColor: widget.retroColors.surfaceRaised,
                  style: AppTextStyles.bodyMedium(color: widget.retroColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'steps', child: Text('Steps')),
                    DropdownMenuItem(value: 'distance', child: Text('Distance (km)')),
                    DropdownMenuItem(value: 'duration', child: Text('Duration (min)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _monthlyMetric = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _mCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMedium(color: widget.retroColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Target',
                    labelStyle: AppTextStyles.label(color: widget.retroColors.textSecondary),
                    filled: true,
                    fillColor: widget.retroColors.surfaceRaised,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.retroColors.accent,
              foregroundColor: widget.retroColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('SAVE GOALS', style: AppTextStyles.labelCaps(color: widget.retroColors.background)),
          ),
        ],
      ),
    );
  }
}
