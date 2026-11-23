import 'package:isar/isar.dart';

part 'weekly_report_isar.g.dart';

@collection
class WeeklyReportIsar {
  Id id = Isar.autoIncrement;

  int? year;
  int? weekNumber;
  DateTime? startDate;
  DateTime? endDate;
  double? totalDistanceM;
  int? totalDurationS;
  double? totalCalories;
  int? totalSteps;
  int? runCount;
  int? walkCount;
  double? avgPaceSPerKm;
  double? avgCadenceSpm;
  double? avgStrideLengthM;
  
  // Store dailyStats as serialized JSON string for simplicity in Isar
  String? dailyStatsJson;
}
