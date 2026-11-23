import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';
import '../../shoes/data/models/shoe_isar.dart';
import '../../run_tracking/data/models/daily_steps_isar.dart';
import '../../stats/data/models/personal_record_isar.dart';
import '../../stats/data/models/weekly_report_isar.dart';
import '../../history/application/gpx_export_util.dart';

class DataExportService {
  final Isar isar;

  DataExportService(this.isar);

  /// Compiles all local database tables into a structured JSON map
  Future<Map<String, dynamic>> generateExportData() async {
    final runs = await isar.runIsars.where().findAll();
    final points = await isar.runPointIsars.where().findAll();
    final shoes = await isar.shoeIsars.where().findAll();
    final steps = await isar.dailyStepsIsars.where().findAll();
    final prs = await isar.personalRecordIsars.where().findAll();
    final reports = await isar.weeklyReportIsars.where().findAll();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final prefsMap = <String, dynamic>{};
    for (final key in keys) {
      prefsMap[key] = prefs.get(key);
    }

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'runs': runs.map((r) => {
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
      }).toList(),
      'points': points.map((p) => {
        'clientRunId': p.clientRunId,
        'lat': p.lat,
        'lng': p.lng,
        'elevation': p.elevation,
        'timestamp': p.timestamp?.toIso8601String(),
        'accuracy': p.accuracy,
        'cadence': p.cadence,
        'sequence': p.sequence,
      }).toList(),
      'shoes': shoes.map((s) => {
        'clientShoeId': s.clientShoeId,
        'name': s.name,
        'brand': s.brand,
        'imageUrl': s.imageUrl,
        'distanceM': s.distanceM,
        'isActive': s.isActive,
        'createdAt': s.createdAt?.toIso8601String(),
      }).toList(),
      'steps': steps.map((st) => {
        'dateKey': st.dateKey,
        'steps': st.steps,
        'hourlySteps': st.hourlySteps,
        'lastPedometerValue': st.lastPedometerValue,
        'lastUpdated': st.lastUpdated?.toIso8601String(),
      }).toList(),
      'personalRecords': prs.map((p) => {
        'category': p.category,
        'runId': p.runId,
        'value': p.value,
        'achievedAt': p.achievedAt?.toIso8601String(),
        'rank': p.rank,
        'source': p.source,
        'proofUrl': p.proofUrl,
      }).toList(),
      'weeklyReports': reports.map((rep) => {
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
      }).toList(),
      'preferences': prefsMap,
    };
  }

  /// Writes data to a temporary file (ideal for sharing via system share sheet)
  Future<File> exportData() async {
    final data = await generateExportData();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/trailhead_export.json');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Resolves the device's public or user-accessible Downloads directory
  static Future<Directory> getDownloadsDirectoryPath() async {
    if (Platform.isAndroid) {
      final defaultDownloads = Directory('/storage/emulated/0/Download');
      if (await defaultDownloads.exists()) {
        return defaultDownloads;
      }
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          return extDirs.first;
        }
      } catch (_) {}
      return (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      return (await getDownloadsDirectory()) ?? (await getApplicationDocumentsDirectory());
    }
  }

  /// Exports full JSON backup directly into the user-accessible Downloads folder
  Future<File> saveBackupToDownloads({String? customFileName}) async {
    final data = await generateExportData();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = customFileName ?? 'trailhead_backup_$dateStr.json';

    final downloadDir = await getDownloadsDirectoryPath();
    final file = File('${downloadDir.path}/$fileName');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Exports all completed GPS runs as individual .gpx files into Downloads/Trailhead_GPX/
  Future<int> exportAllRunsGpxToDownloads() async {
    final runs = await isar.runIsars.where().filter().statusEqualTo('completed').findAll();
    final downloadDir = await getDownloadsDirectoryPath();
    final gpxDir = Directory('${downloadDir.path}/Trailhead_GPX');
    if (!await gpxDir.exists()) {
      await gpxDir.create(recursive: true);
    }

    int exportedCount = 0;
    for (final run in runs) {
      if (run.clientRunId == null) continue;
      final points = await isar.runPointIsars.where().filter().clientRunIdEqualTo(run.clientRunId!).findAll();
      if (points.length < 2) continue;

      final gpxXml = GpxExportUtil.generateGpxXml(run, points);
      final dateStr = run.startTime != null
          ? '${run.startTime!.year}${run.startTime!.month.toString().padLeft(2, '0')}${run.startTime!.day.toString().padLeft(2, '0')}'
          : 'unknown_date';
      final distKm = ((run.distanceM ?? 0) / 1000).toStringAsFixed(1);
      final safeTitle = (run.title ?? 'run').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'trailhead_${safeTitle}_${distKm}km_$dateStr.gpx';

      final file = File('${gpxDir.path}/$fileName');
      await file.writeAsString(gpxXml);
      exportedCount++;
    }
    return exportedCount;
  }
}
