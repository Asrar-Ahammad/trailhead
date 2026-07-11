class DailyStat {
  final int day;
  final double avgPace;
  final double avgCadence;

  DailyStat({
    required this.day,
    required this.avgPace,
    required this.avgCadence,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      day: json['day'] as int,
      avgPace: (json['avgPace'] as num).toDouble(),
      avgCadence: (json['avgCadence'] as num).toDouble(),
    );
  }
}

class WeeklyReportModel {
  final String id;
  final int year;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDistanceM;
  final int totalDurationS;
  final double totalCalories;
  final int totalSteps;
  final int runCount;
  final int walkCount;
  final double avgPaceSPerKm;
  final double avgCadenceSpm;
  final double avgStrideLengthM;
  final List<DailyStat> dailyStats;

  WeeklyReportModel({
    required this.id,
    required this.year,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.totalDistanceM,
    required this.totalDurationS,
    required this.totalCalories,
    required this.totalSteps,
    required this.runCount,
    required this.walkCount,
    required this.avgPaceSPerKm,
    required this.avgCadenceSpm,
    required this.avgStrideLengthM,
    required this.dailyStats,
  });

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportModel(
      id: json['id'] as String,
      year: json['year'] as int,
      weekNumber: json['weekNumber'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDistanceM: (json['totalDistanceM'] as num).toDouble(),
      totalDurationS: json['totalDurationS'] as int,
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalSteps: json['totalSteps'] as int,
      runCount: json['runCount'] as int,
      walkCount: json['walkCount'] as int,
      avgPaceSPerKm: (json['avgPaceSPerKm'] as num).toDouble(),
      avgCadenceSpm: (json['avgCadenceSpm'] as num).toDouble(),
      avgStrideLengthM: (json['avgStrideLengthM'] as num).toDouble(),
      dailyStats: (json['dailyStats'] as List<dynamic>?)
              ?.map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
