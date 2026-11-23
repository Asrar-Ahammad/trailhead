import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/main.dart'; // import global isarInstance
import 'models/weekly_report_model.dart';
import 'models/weekly_report_isar.dart';

final weeklyReportServiceProvider = Provider((ref) {
  return WeeklyReportService(isarInstance);
});

final weeklyReportsProvider = FutureProvider<List<WeeklyReportModel>>((ref) async {
  final service = ref.watch(weeklyReportServiceProvider);
  await service.generateWeeklyReports();
  return service.getWeeklyReportsHistory();
});

class WeeklyReportService {
  final Isar _isar;

  WeeklyReportService(this._isar);

  Future<void> generateWeeklyReports() async {
    final completedRuns = await _isar.runIsars.filter().statusEqualTo('completed').findAll();
    if (completedRuns.isEmpty) return;

    // Group runs by year and ISO week number
    final groupedRuns = <String, List<RunIsar>>{};
    for (final run in completedRuns) {
      if (run.startTime == null) continue;
      final time = run.startTime!;
      
      // Calculate ISO week number
      final year = time.year;
      final weekNum = _getIsoWeekNumber(time);
      final key = '${year}_$weekNum';
      groupedRuns.putIfAbsent(key, () => []).add(run);
    }

    await _isar.writeTxn(() async {
      for (final entry in groupedRuns.entries) {
        final parts = entry.key.split('_');
        final year = int.parse(parts[0]);
        final weekNum = int.parse(parts[1]);
        final runs = entry.value;

        // Calculate stats
        double totalDistanceM = 0;
        int totalDurationS = 0;
        double totalCalories = 0;
        int totalSteps = 0;
        int runCount = 0;
        int walkCount = 0;
        double totalPace = 0;
        int paceCount = 0;
        double totalCadence = 0;
        int cadenceCount = 0;
        double totalStride = 0;
        int strideCount = 0;

        final dailyStatsList = <Map<String, dynamic>>[];

        for (final r in runs) {
          totalDistanceM += r.distanceM ?? 0;
          totalDurationS += r.durationS ?? 0;
          totalCalories += r.caloriesKcal ?? 0;
          totalSteps += r.stepCount ?? 0;

          if (r.activityType == 'walk') {
            walkCount++;
          } else {
            runCount++;
          }

          if (r.avgPaceSPerKm != null && r.avgPaceSPerKm! > 0) {
            totalPace += r.avgPaceSPerKm!;
            paceCount++;
          }
          if (r.avgCadenceSpm != null && r.avgCadenceSpm! > 0) {
            totalCadence += r.avgCadenceSpm!;
            cadenceCount++;
          }
          if (r.avgStrideLengthM != null && r.avgStrideLengthM! > 0) {
            totalStride += r.avgStrideLengthM!;
            strideCount++;
          }

          if (r.startTime != null) {
            dailyStatsList.add({
              'day': r.startTime!.weekday,
              'avgPace': r.avgPaceSPerKm ?? 0.0,
              'avgCadence': r.avgCadenceSpm ?? 0.0,
            });
          }
        }

        // Find existing report
        var report = await _isar.weeklyReportIsars
            .filter()
            .yearEqualTo(year)
            .and()
            .weekNumberEqualTo(weekNum)
            .findFirst();

        if (report == null) {
          report = WeeklyReportIsar()
            ..year = year
            ..weekNumber = weekNum;
        }

        report
          ..startDate = _getStartOfWeek(year, weekNum)
          ..endDate = _getStartOfWeek(year, weekNum).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59))
          ..totalDistanceM = totalDistanceM
          ..totalDurationS = totalDurationS
          ..totalCalories = totalCalories
          ..totalSteps = totalSteps
          ..runCount = runCount
          ..walkCount = walkCount
          ..avgPaceSPerKm = paceCount > 0 ? totalPace / paceCount : 0.0
          ..avgCadenceSpm = cadenceCount > 0 ? totalCadence / cadenceCount : 0.0
          ..avgStrideLengthM = strideCount > 0 ? totalStride / strideCount : 0.0
          ..dailyStatsJson = jsonEncode(dailyStatsList);

        await _isar.weeklyReportIsars.put(report);
      }
    });
  }

  Future<List<WeeklyReportModel>> getWeeklyReportsHistory() async {
    final reports = await _isar.weeklyReportIsars.where().sortByYearDesc().thenByWeekNumberDesc().findAll();
    return reports.map((r) {
      final List<dynamic> statsList = r.dailyStatsJson != null ? jsonDecode(r.dailyStatsJson!) : [];
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
        dailyStats: statsList.map((e) => DailyStat.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }).toList();
  }

  int _getIsoWeekNumber(DateTime date) {
    // ISO week date calendar
    final dayOfYear = int.parse(_formatDate(date, 'D'));
    final wday = date.weekday;
    var week = ((dayOfYear - wday + 10) / 7).floor();
    if (week < 1) {
      week = _getIsoWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (week > 52) {
      if (DateTime(date.year + 1, 1, 1).weekday <= 4) {
        week = 1;
      }
    }
    return week;
  }

  DateTime _getStartOfWeek(int year, int week) {
    final jan1 = DateTime(year, 1, 1);
    final jan1Weekday = jan1.weekday;
    final firstThursday = jan1Weekday <= 4 
        ? jan1.subtract(Duration(days: jan1Weekday - 4))
        : jan1.add(Duration(days: 8 - jan1Weekday));
    final targetThursday = firstThursday.add(Duration(days: (week - 1) * 7));
    return targetThursday.subtract(const Duration(days: 3)); // Thursday to Monday
  }

  String _formatDate(DateTime date, String format) {
    if (format == 'D') {
      final diff = date.difference(DateTime(date.year, 1, 1));
      return (diff.inDays + 1).toString();
    }
    return '';
  }
}
