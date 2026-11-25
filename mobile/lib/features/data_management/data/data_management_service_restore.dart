import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';
import '../../shoes/data/models/shoe_isar.dart';
import '../../run_tracking/data/models/daily_steps_isar.dart';
import '../../stats/data/models/personal_record_isar.dart';
import '../../stats/data/models/weekly_report_isar.dart';
import 'data_management_request_model_restore.dart';
import 'data_management_response_model_restore.dart';

class DataImportService {
  final Isar isar;
  final SharedPreferences _preferences;

  DataImportService(this.isar, this._preferences);

  Future<RestoreBackupResponseModel> restore(
    RestoreBackupRequestModel request,
  ) async {
    final content = await File(request.path).readAsString();
    final data = await compute(jsonDecode, content) as Map<String, dynamic>;

    if (data['version'] != 1) {
      throw const FormatException('Unsupported file version');
    }
    final preferences = (data['preferences'] as Map<String, dynamic>? ?? {})
        .map(
          (key, value) =>
              MapEntry(key, value is List ? List<String>.from(value) : value),
        );

    await isar.writeTxn(() async {
      if (request.overwrite) {
        await isar.runIsars.clear();
        await isar.runPointIsars.clear();
        await isar.shoeIsars.clear();
        await isar.dailyStepsIsars.clear();
        await isar.personalRecordIsars.clear();
        await isar.weeklyReportIsars.clear();
      }

      // Import shoes
      final shoesList = data['shoes'] as List<dynamic>? ?? [];
      for (final s in shoesList) {
        final shoe = ShoeIsar()
          ..clientShoeId = s['clientShoeId']
          ..name = s['name']
          ..brand = s['brand']
          ..imageUrl = s['imageUrl']
          ..distanceM = (s['distanceM'] as num?)?.toDouble() ?? 0.0
          ..isActive = s['isActive'] ?? true
          ..createdAt = s['createdAt'] != null
              ? DateTime.parse(s['createdAt'])
              : null;
        await isar.shoeIsars.put(shoe);
      }

      // Import runs
      final runsList = data['runs'] as List<dynamic>? ?? [];
      for (final r in runsList) {
        final run = RunIsar()
          ..clientRunId = r['clientRunId']
          ..clientShoeId = r['clientShoeId']
          ..title = r['title']
          ..startTime = r['startTime'] != null
              ? DateTime.parse(r['startTime'])
              : null
          ..endTime = r['endTime'] != null ? DateTime.parse(r['endTime']) : null
          ..distanceM = (r['distanceM'] as num?)?.toDouble()
          ..durationS = r['durationS'] as int?
          ..avgPaceSPerKm = (r['avgPaceSPerKm'] as num?)?.toDouble()
          ..elevationGainM = (r['elevationGainM'] as num?)?.toDouble()
          ..activityType = r['activityType']
          ..stepCount = r['stepCount'] as int?
          ..avgStrideLengthM = (r['avgStrideLengthM'] as num?)?.toDouble()
          ..avgCadenceSpm = (r['avgCadenceSpm'] as num?)?.toDouble()
          ..avgGapSPerKm = (r['avgGapSPerKm'] as num?)?.toDouble()
          ..caloriesKcal = (r['caloriesKcal'] as num?)?.toDouble()
          ..status = r['status']
          ..aiSummary = r['aiSummary']
          ..aiAnalysis = r['aiAnalysis']
          ..subjectiveEffort = r['subjectiveEffort']
          ..conditions = r['conditions']
          ..weatherTemp = (r['weatherTemp'] as num?)?.toDouble()
          ..weatherCode = (r['weatherCode'] as num?)?.toDouble();
        await isar.runIsars.put(run);
      }

      // Import points
      final pointsList = data['points'] as List<dynamic>? ?? [];
      for (final p in pointsList) {
        final pt = RunPointIsar()
          ..clientRunId = p['clientRunId']
          ..lat = (p['lat'] as num).toDouble()
          ..lng = (p['lng'] as num).toDouble()
          ..elevation = (p['elevation'] as num?)?.toDouble()
          ..timestamp = p['timestamp'] != null
              ? DateTime.parse(p['timestamp'])
              : null
          ..accuracy = (p['accuracy'] as num?)?.toDouble()
          ..cadence = p['cadence'] as int?
          ..sequence = p['sequence'] as int;
        await isar.runPointIsars.put(pt);
      }

      // Import daily steps
      final stepsList = data['steps'] as List<dynamic>? ?? [];
      for (final st in stepsList) {
        final steps = DailyStepsIsar()
          ..dateKey = st['dateKey']
          ..steps = st['steps'] ?? 0
          ..hourlySteps = List<int>.from(
            st['hourlySteps'] ?? List.filled(24, 0),
          )
          ..lastPedometerValue = st['lastPedometerValue'] ?? 0
          ..lastUpdated = st['lastUpdated'] != null
              ? DateTime.parse(st['lastUpdated'])
              : null;
        await isar.dailyStepsIsars.put(steps);
      }

      // Import personal records
      final prList = data['personalRecords'] as List<dynamic>? ?? [];
      for (final p in prList) {
        final pr = PersonalRecordIsar()
          ..category = p['category']
          ..runId = p['runId']
          ..value = (p['value'] as num?)?.toDouble()
          ..achievedAt = p['achievedAt'] != null
              ? DateTime.parse(p['achievedAt'])
              : null
          ..rank = p['rank'] as int?
          ..source = p['source']
          ..proofUrl = p['proofUrl'];
        await isar.personalRecordIsars.put(pr);
      }

      // Import weekly reports
      final reportsList = data['weeklyReports'] as List<dynamic>? ?? [];
      for (final rep in reportsList) {
        final report = WeeklyReportIsar()
          ..year = rep['year']
          ..weekNumber = rep['weekNumber']
          ..startDate = rep['startDate'] != null
              ? DateTime.parse(rep['startDate'])
              : null
          ..endDate = rep['endDate'] != null
              ? DateTime.parse(rep['endDate'])
              : null
          ..totalDistanceM = (rep['totalDistanceM'] as num?)?.toDouble()
          ..totalDurationS = rep['totalDurationS'] as int?
          ..totalCalories = (rep['totalCalories'] as num?)?.toDouble()
          ..totalSteps = rep['totalSteps'] as int?
          ..runCount = rep['runCount'] as int?
          ..walkCount = rep['walkCount'] as int?
          ..avgPaceSPerKm = (rep['avgPaceSPerKm'] as num?)?.toDouble()
          ..avgCadenceSpm = (rep['avgCadenceSpm'] as num?)?.toDouble()
          ..avgStrideLengthM = (rep['avgStrideLengthM'] as num?)?.toDouble()
          ..dailyStatsJson = rep['dailyStatsJson'];
        await isar.weeklyReportIsars.put(report);
      }
    });

    // Restore preferences
    final prefs = _preferences;
    for (final entry in preferences.entries) {
      final val = entry.value;
      if (val is bool) {
        await prefs.setBool(entry.key, val);
      } else if (val is double) {
        await prefs.setDouble(entry.key, val);
      } else if (val is int) {
        await prefs.setInt(entry.key, val);
      } else if (val is String) {
        await prefs.setString(entry.key, val);
      } else if (val is List<String>) {
        await prefs.setStringList(entry.key, val);
      }
    }

    return RestoreBackupResponseModel(
      runs: (data['runs'] as List?)?.length ?? 0,
      shoes: (data['shoes'] as List?)?.length ?? 0,
    );
  }
}
