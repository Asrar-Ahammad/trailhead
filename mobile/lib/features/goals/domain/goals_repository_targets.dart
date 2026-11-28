class Goals {
  const Goals({
    required this.dailyGoalMetric,
    required this.dailyGoalTarget,
    required this.monthlyGoalMetric,
    required this.monthlyGoalTarget,
  });

  const Goals.empty()
    : dailyGoalMetric = 'steps',
      dailyGoalTarget = 5000,
      monthlyGoalMetric = 'distance',
      monthlyGoalTarget = 50;

  final String dailyGoalMetric;
  final double dailyGoalTarget;
  final String monthlyGoalMetric;
  final double monthlyGoalTarget;

  Goals normalizeLegacyMonthlyGoal() => monthlyGoalMetric == 'steps'
      ? Goals(
          dailyGoalMetric: dailyGoalMetric,
          dailyGoalTarget: dailyGoalTarget,
          monthlyGoalMetric: 'distance',
          monthlyGoalTarget: 50,
        )
      : this;

  static Goals parseTargets(
    String dailyMetric,
    String daily,
    String monthlyMetric,
    String monthly,
  ) {
    final dailyTarget = double.tryParse(daily);
    final monthlyTarget = double.tryParse(monthly);
    if (dailyTarget == null ||
        !dailyTarget.isFinite ||
        dailyTarget <= 0 ||
        monthlyTarget == null ||
        !monthlyTarget.isFinite ||
        monthlyTarget <= 0) {
      throw const FormatException('Enter positive numbers for both targets.');
    }
    return Goals(
      dailyGoalMetric: dailyMetric,
      dailyGoalTarget: dailyTarget,
      monthlyGoalMetric: monthlyMetric,
      monthlyGoalTarget: monthlyTarget,
    );
  }
}

abstract interface class GoalsRepository {
  Future<Goals> load();
  Future<void> save(Goals goals);
}
