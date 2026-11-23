import 'package:isar/isar.dart';

part 'goal_isar.g.dart';

@collection
class GoalIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String key = 'user_goals';

  String dailyGoalMetric = 'steps';
  double dailyGoalTarget = 5000.0;
  String monthlyGoalMetric = 'steps';
  double monthlyGoalTarget = 150000.0;
}
