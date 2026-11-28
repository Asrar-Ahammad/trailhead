import 'widgets/goals_widget_target_fields.dart';
import 'package:trailhead_mobile/shared/widgets/inset_sheet_body.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/state_management/global/goals_cubit_targets.dart';
import '../domain/goals_repository_targets.dart';
import '../state_management/goals_bloc_edit_targets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class SetGoalsSheet extends StatelessWidget {
  final AppColors retroColors;
  const SetGoalsSheet({super.key, required this.retroColors});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateEditGoalsBloc>()(),
    child: _GoalsForm(retroColors: retroColors),
  );
}

class _GoalsForm extends StatefulWidget {
  const _GoalsForm({required this.retroColors});
  final AppColors retroColors;

  @override
  State<_GoalsForm> createState() => _SetGoalsSheetState();
}

class _SetGoalsSheetState extends State<_GoalsForm> {
  late String _dailyMetric;
  late String _monthlyMetric;

  final _dCtrl = TextEditingController();
  final _mCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final goals = context.read<GoalsCubit>().state.valueOrNull ?? Goals.empty();
    _dailyMetric = goals.dailyGoalMetric;
    _monthlyMetric = goals.monthlyGoalMetric;
    _dCtrl.text = _formatTarget(goals.dailyGoalTarget);
    _mCtrl.text = _formatTarget(goals.monthlyGoalTarget);
  }

  String _formatTarget(double target) =>
      target.isFinite && target == target.truncateToDouble()
      ? target.toStringAsFixed(0)
      : target.toString();

  @override
  void dispose() {
    _dCtrl.dispose();
    _mCtrl.dispose();
    super.dispose();
  }

  void _save() => context.read<EditGoalsBloc>().add((
    dailyMetric: _dailyMetric,
    daily: _dCtrl.text,
    monthlyMetric: _monthlyMetric,
    monthly: _mCtrl.text,
  ));

  @override
  Widget build(BuildContext context) {
    final saving = context.select((EditGoalsBloc bloc) => bloc.state.saving);
    return BlocListener<
      EditGoalsBloc,
      ({bool saving, bool saved, String? error})
    >(
      listener: (context, state) {
        if (state.saved && ModalRoute.of(context)?.isCurrent == true) {
          AppNavigator.pop(context);
        }
        if (state.error case final error?) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      child: InsetSheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SET GOALS',
                  style: AppTextStyles.title(
                    color: widget.retroColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => AppNavigator.pop(context),
                  icon: Icon(
                    PhosphorIcons.x,
                    color: widget.retroColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'DAILY GOAL',
              style: AppTextStyles.label(color: widget.retroColors.accent),
            ),
            const SizedBox(height: 8),
            GoalTargetFields(
              metric: _dailyMetric,
              target: _dCtrl,
              onMetricChanged: (value) => setState(() => _dailyMetric = value),
              colors: widget.retroColors,
              includeSteps: true,
            ),
            const SizedBox(height: 32),
            Text(
              'MONTHLY GOAL',
              style: AppTextStyles.label(color: widget.retroColors.accent),
            ),
            const SizedBox(height: 8),
            GoalTargetFields(
              metric: _monthlyMetric,
              target: _mCtrl,
              onMetricChanged: (value) =>
                  setState(() => _monthlyMetric = value),
              colors: widget.retroColors,
              includeSteps: false,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.retroColors.accent,
                foregroundColor: widget.retroColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'SAVE GOALS',
                style: AppTextStyles.labelCaps(
                  color: widget.retroColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
