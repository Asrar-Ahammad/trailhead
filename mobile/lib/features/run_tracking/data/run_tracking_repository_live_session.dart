import 'package:latlong2/latlong.dart';
import 'package:isar/isar.dart';
import '../domain/run_tracking_use_case_session_metrics.dart';
import 'models/daily_steps_isar.dart';
import 'models/run_isar.dart';
import 'models/run_point_isar.dart';

class LiveSessionRepository {
  LiveSessionRepository(this.isar);
  final Isar isar;

  Future<List<RunIsar>> unfinished() => isar.runIsars
      .filter()
      .statusEqualTo('running')
      .or()
      .statusEqualTo('paused')
      .findAll();

  Future<void> save(RunIsar run) async {
    await isar.writeTxn(() => isar.runIsars.put(run));
  }

  Future<void> finalizeOrphans(Iterable<RunIsar> runs, DateTime now) async {
    await isar.writeTxn(
      () => isar.runIsars.putAll(
        runs
            .map(
              (run) => run
                ..status = 'completed'
                ..endTime = now
                ..lastModifiedAt = now,
            )
            .toList(),
      ),
    );
  }

  Future<List<LatLng>> readRoute(String id) async {
    final rows = await isar.runPointIsars
        .filter()
        .clientRunIdEqualTo(id)
        .sortBySequence()
        .findAll();
    return rows
        .where((point) => point.lat != null && point.lng != null)
        .map((point) => LatLng(point.lat!, point.lng!))
        .toList(growable: false);
  }

  Future<void> addPoint(RunPointIsar point) async {
    await isar.writeTxn(() => isar.runPointIsars.put(point));
  }

  Future<void> saveWeather(String id, double temp, double code) async {
    await _edit(id, (run) {
      run.weatherTemp = temp;
      run.weatherCode = code;
    });
  }

  Future<void> saveProgress(String id, SessionMetrics metrics) async {
    await _edit(id, (run) {
      if (run.status != 'completed') _setMetrics(run, metrics);
    });
  }

  Future<void> setStatus(
    String? id,
    String status, {
    double? distance,
    int? duration,
  }) async {
    await _edit(id, (run) {
      if (run.status == 'completed') return;
      run.status = status;
      if (distance != null) run.distanceM = distance;
      if (duration != null) run.durationS = duration;
    });
  }

  Future<RunIsar?> complete(
    String? id,
    SessionMetrics metrics,
    DateTime now,
    String? shoeId,
  ) => _edit(id, (run) {
    _setMetrics(run, metrics);
    run
      ..status = 'completed'
      ..endTime = now
      ..clientShoeId = shoeId
      ..lastModifiedAt = now;
  });

  void _setMetrics(RunIsar run, SessionMetrics metrics) {
    run
      ..distanceM = metrics.distance
      ..durationS = metrics.duration
      ..stepCount = metrics.steps
      ..elevationGainM = metrics.elevation
      ..caloriesKcal = metrics.calories;
    if (metrics.stride case final stride?) run.avgStrideLengthM = stride;
    if (metrics.cadence case final cadence?) run.avgCadenceSpm = cadence;
    if (metrics.pace case final pace?) run.avgPaceSPerKm = pace;
  }

  Future<RunIsar?> _edit(String? id, void Function(RunIsar) apply) {
    if (id == null) return Future.value(null);
    return isar.writeTxn(() async {
      final run = await isar.runIsars
          .filter()
          .clientRunIdEqualTo(id)
          .findFirst();
      if (run == null) return null;
      apply(run);
      await isar.runIsars.put(run);
      return run;
    });
  }

  Future<void> discard(String id) => isar.writeTxn(() async {
    await isar.runIsars.filter().clientRunIdEqualTo(id).deleteAll();
    await isar.runPointIsars.filter().clientRunIdEqualTo(id).deleteAll();
  });

  Future<void> addDailySteps(DateTime now, int delta, int rawSteps) =>
      isar.writeTxn(() async {
        final key = now.toIso8601String().split('T').first;
        final record =
            await isar.dailyStepsIsars
                .filter()
                .dateKeyEqualTo(key)
                .findFirst() ??
            (DailyStepsIsar()..dateKey = key);
        final hours = record.hourlySteps.length == 24
            ? record.hourlySteps.toList()
            : List<int>.filled(24, 0);
        hours[now.hour] += delta;
        record
          ..steps += delta
          ..hourlySteps = hours
          ..lastPedometerValue = rawSteps
          ..lastUpdated = now;
        await isar.dailyStepsIsars.put(record);
      });
}
