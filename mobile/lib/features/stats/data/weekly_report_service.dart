import 'dart:convert';
import '../domain/stats_use_case_weekly_report.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'models/weekly_report_model.dart';
import 'models/weekly_report_isar.dart';

class WeeklyReportService {
  final Isar _isar;

  WeeklyReportService(this._isar);

  Future<List<WeeklyReportModel>> loadReports() async {
    await generateWeeklyReports();
    return getWeeklyReportsHistory();
  }

  Future<void> generateWeeklyReports() => _isar.writeTxn(() async {
    final runs = await _isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .findAll();
    final groups = <IsoWeek, List<WeeklyActivity>>{};
    for (final run in runs) {
      final date = run.startTime;
      if (date == null) continue;
      groups.putIfAbsent(isoWeekFor(date), () => []).add((
        start: date,
        distance: run.distanceM ?? 0,
        duration: run.durationS ?? 0,
        calories: run.caloriesKcal ?? 0,
        steps: run.stepCount ?? 0,
        walk: run.activityType == 'walk',
        pace: run.avgPaceSPerKm ?? 0,
        cadence: run.avgCadenceSpm ?? 0,
        stride: run.avgStrideLengthM ?? 0,
      ));
    }
    final cached = await _isar.weeklyReportIsars.where().findAll();
    final existing = {
      for (final report in cached)
        (year: report.year, number: report.weekNumber): report,
    };
    final activeIds = <int>{};
    for (final MapEntry(key: week, value: activities) in groups.entries) {
      final totals = WeeklyTotals(activities);
      final start = startOfIsoWeek(week);
      final report = existing[week] ?? WeeklyReportIsar();
      report
        ..year = week.year
        ..weekNumber = week.number
        ..startDate = start
        ..endDate = DateTime(
          start.year,
          start.month,
          start.day + 7,
        ).subtract(const Duration(seconds: 1))
        ..totalDistanceM = totals.distance
        ..totalDurationS = totals.duration
        ..totalCalories = totals.calories
        ..totalSteps = totals.steps
        ..runCount = totals.count - totals.walks
        ..walkCount = totals.walks
        ..avgPaceSPerKm = totals.pace
        ..avgCadenceSpm = totals.cadence
        ..avgStrideLengthM = totals.stride
        ..dailyStatsJson = jsonEncode(
          activities
              .map(
                (run) => {
                  'day': run.start.weekday,
                  'avgPace': run.pace,
                  'avgCadence': run.cadence,
                },
              )
              .toList(),
        );
      activeIds.add(await _isar.weeklyReportIsars.put(report));
    }
    await _isar.weeklyReportIsars.deleteAll(
      cached
          .where((report) => !activeIds.contains(report.id))
          .map((report) => report.id)
          .toList(),
    );
  });

  Future<List<WeeklyReportModel>> getWeeklyReportsHistory() async {
    final reports = await _isar.weeklyReportIsars
        .where()
        .sortByYearDesc()
        .thenByWeekNumberDesc()
        .findAll();
    return reports.map((r) {
      final List<dynamic> statsList = r.dailyStatsJson != null
          ? jsonDecode(r.dailyStatsJson!)
          : [];
      return WeeklyReportModel(
        id: r.id.toString(),
        year: r.year ?? 0,
        weekNumber: r.weekNumber ?? 0,
        startDate: r.startDate ?? DateTime.now(),
        endDate: r.endDate ?? DateTime.now(),
        totalDistanceM: r.totalDistanceM ?? 0.0,
        totalDurationS: r.totalDurationS ?? 0,
        totalCalories: r.totalCalories ?? 0.0,
        totalSteps: r.totalSteps ?? 0,
        runCount: r.runCount ?? 0,
        walkCount: r.walkCount ?? 0,
        avgPaceSPerKm: r.avgPaceSPerKm ?? 0.0,
        avgCadenceSpm: r.avgCadenceSpm ?? 0.0,
        avgStrideLengthM: r.avgStrideLengthM ?? 0.0,
        dailyStats: statsList
            .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }
}
