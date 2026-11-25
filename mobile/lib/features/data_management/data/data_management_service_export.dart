import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/data_management_use_case_name_exports.dart';
import '../../../shared/files/downloads_directory.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';
import '../../shoes/data/models/shoe_isar.dart';
import '../../run_tracking/data/models/daily_steps_isar.dart';
import '../../stats/data/models/personal_record_isar.dart';
import '../../stats/data/models/weekly_report_isar.dart';
import '../../history/application/gpx_export_util.dart';

class DataExportService {
  final Isar isar;
  final SharedPreferences _preferences;

  DataExportService(this.isar, this._preferences);

  /// Compiles all local database tables into a structured JSON map
  Future<Map<String, dynamic>> generateExportData() async {
    final runs = await isar.runIsars.where().findAll();
    final points = await isar.runPointIsars.where().findAll();
    final shoes = await isar.shoeIsars.where().findAll();
    final steps = await isar.dailyStepsIsars.where().findAll();
    final prs = await isar.personalRecordIsars.where().findAll();
    final reports = await isar.weeklyReportIsars.where().findAll();

    final prefs = _preferences;
    final keys = prefs.getKeys();
    final prefsMap = <String, dynamic>{};
    for (final key in keys) {
      prefsMap[key] = prefs.get(key);
    }

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'runs': runs
          .map(
            (r) => {
              'clientRunId': r.clientRunId,
              'clientShoeId': r.clientShoeId,
              'title': r.title,
              'startTime': r.startTime?.toIso8601String(),
              'endTime': r.endTime?.toIso8601String(),
              'distanceM': r.distanceM,
              'durationS': r.durationS,
              'avgPaceSPerKm': r.avgPaceSPerKm,
              'elevationGainM': r.elevationGainM,
              'activityType': r.activityType,
              'stepCount': r.stepCount,
              'avgStrideLengthM': r.avgStrideLengthM,
              'avgCadenceSpm': r.avgCadenceSpm,
              'avgGapSPerKm': r.avgGapSPerKm,
              'caloriesKcal': r.caloriesKcal,
              'status': r.status,
              'aiSummary': r.aiSummary,
              'aiAnalysis': r.aiAnalysis,
              'subjectiveEffort': r.subjectiveEffort,
              'conditions': r.conditions,
              'weatherTemp': r.weatherTemp,
              'weatherCode': r.weatherCode,
            },
          )
          .toList(),
      'points': points
          .map(
            (p) => {
              'clientRunId': p.clientRunId,
              'lat': p.lat,
              'lng': p.lng,
              'elevation': p.elevation,
              'timestamp': p.timestamp?.toIso8601String(),
              'accuracy': p.accuracy,
              'cadence': p.cadence,
              'sequence': p.sequence,
            },
          )
          .toList(),
      'shoes': shoes
          .map(
            (s) => {
              'clientShoeId': s.clientShoeId,
              'name': s.name,
              'brand': s.brand,
              'imageUrl': s.imageUrl,
              'distanceM': s.distanceM,
              'isActive': s.isActive,
              'createdAt': s.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'steps': steps
          .map(
            (st) => {
              'dateKey': st.dateKey,
              'steps': st.steps,
              'hourlySteps': st.hourlySteps,
              'lastPedometerValue': st.lastPedometerValue,
              'lastUpdated': st.lastUpdated?.toIso8601String(),
            },
          )
          .toList(),
      'personalRecords': prs
          .map(
            (p) => {
              'category': p.category,
              'runId': p.runId,
              'value': p.value,
              'achievedAt': p.achievedAt?.toIso8601String(),
              'rank': p.rank,
              'source': p.source,
              'proofUrl': p.proofUrl,
            },
          )
          .toList(),
      'weeklyReports': reports
          .map(
            (rep) => {
              'year': rep.year,
              'weekNumber': rep.weekNumber,
              'startDate': rep.startDate?.toIso8601String(),
              'endDate': rep.endDate?.toIso8601String(),
              'totalDistanceM': rep.totalDistanceM,
              'totalDurationS': rep.totalDurationS,
              'totalCalories': rep.totalCalories,
              'totalSteps': rep.totalSteps,
              'runCount': rep.runCount,
              'walkCount': rep.walkCount,
              'avgPaceSPerKm': rep.avgPaceSPerKm,
              'avgCadenceSpm': rep.avgCadenceSpm,
              'avgStrideLengthM': rep.avgStrideLengthM,
              'dailyStatsJson': rep.dailyStatsJson,
            },
          )
          .toList(),
      'preferences': prefsMap,
    };
  }

  /// Writes data to a temporary file (ideal for sharing via system share sheet)
  Future<File> exportData() async {
    final data = await generateExportData();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/trailhead_export.json');
    await file.writeAsString(await compute(jsonEncode, data));
    return file;
  }

  Future<void> _requestDownloadsAccess() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.storage.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      await Permission.storage.request();
    }
  }

  /// Exports full JSON backup directly into the user-accessible Downloads folder
  Future<File> saveBackupToDownloads() async {
    await _requestDownloadsAccess();
    final data = await generateExportData();
    final fileName = backupFileName(DateTime.now());

    final downloadDir = await resolveDownloadsDirectory();
    final file = File('${downloadDir.path}/$fileName');
    await file.writeAsString(await compute(jsonEncode, data));
    return file;
  }

  /// Exports all completed GPS runs as individual .gpx files into Downloads/Trailhead_GPX/
  Future<int> exportAllRunsGpxToDownloads() async {
    await _requestDownloadsAccess();
    final runs = await isar.runIsars
        .where()
        .filter()
        .statusEqualTo('completed')
        .findAll();
    final downloadDir = await resolveDownloadsDirectory();
    final gpxDir = Directory('${downloadDir.path}/Trailhead_GPX');
    if (!await gpxDir.exists()) {
      await gpxDir.create(recursive: true);
    }

    int exportedCount = 0;
    for (final run in runs) {
      if (run.clientRunId == null) continue;
      final points = await isar.runPointIsars
          .where()
          .filter()
          .clientRunIdEqualTo(run.clientRunId!)
          .findAll();
      if (points.length < 2) continue;

      final gpxXml = GpxExportUtil.generateGpxXml(run, points);
      final fileName = routeExportFileName(
        startTime: run.startTime,
        distanceMeters: run.distanceM,
        title: run.title,
      );

      final file = File('${gpxDir.path}/$fileName');
      await file.writeAsString(gpxXml);
      exportedCount++;
    }
    return exportedCount;
  }
}
