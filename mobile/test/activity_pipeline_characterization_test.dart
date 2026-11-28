import 'package:trailhead_mobile/features/you/domain/you_use_case_progress_calendar.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/features/run_tracking/domain/run_tracking_use_case_validate_weight.dart';
import 'package:trailhead_mobile/features/stats/domain/stats_use_case_record_time.dart';
import 'package:trailhead_mobile/features/stats/domain/stats_use_case_weekly_report.dart';
import 'package:trailhead_mobile/features/you/state_management/you_bloc_activity_actions.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_route_map.dart';

void main() {
  test('weekly progress includes a run started exactly at Monday midnight', () {
    final totals = weeklyProgress([
      (date: DateTime(2026, 11, 23), distanceM: 3000.0),
      (date: DateTime(2026, 11, 22, 23, 59), distanceM: 2000.0),
    ], DateTime(2026, 11, 26));
    expect(totals.skip(10), [2, 3]);
  });
  test('ISO reports group December and January runs in the same week', () {
    expect(isoWeekFor(DateTime(2024, 12, 30)), (year: 2025, number: 1));
    expect(isoWeekFor(DateTime(2025, 1, 5)), (year: 2025, number: 1));
    expect(isoWeekFor(DateTime(2021, 1, 1)), (year: 2020, number: 53));
    expect(startOfIsoWeek((year: 2025, number: 1)), DateTime(2024, 12, 30));
  });

  test('manual benchmark and workout weight reject invalid numeric input', () {
    expect(parseRecordTime('22', '30'), 1350);
    expect(() => parseRecordTime('22', '60'), throwsFormatException);
    expect(() => parseRecordTime('0', '-10'), throwsFormatException);
    expect(parseTrackingWeight(' 70.5 '), 70.5);
    expect(() => parseTrackingWeight('NaN'), throwsFormatException);
    expect(() => parseTrackingWeight('Infinity'), throwsFormatException);
  });

  test('bulk delete preserves selection on failure and allows retry', () async {
    var attempts = 0;
    final bloc = YouBloc((ids) async {
      expect(ids, {7, 8});
      attempts++;
      if (attempts == 1) throw StateError('write failed');
    });
    addTearDown(bloc.close);
    final failed = bloc.stream.firstWhere((state) => state.error != null);
    bloc
      ..add(const ToggleActivitySelection(7))
      ..add(const ToggleActivitySelection(8))
      ..add(const DeleteSelectedActivities());
    expect((await failed).selected, {7, 8});
    final deleted = bloc.stream.firstWhere((state) => state.selected.isEmpty);
    bloc.add(const DeleteSelectedActivities());
    expect((await deleted).deleting, isFalse);
    expect(attempts, 2);
  });

  test(
    'map recenters without losing the current route and clears on idle',
    () async {
      final routes = StreamController<List<LatLng>>();
      final cubit = RunRouteMapCubit(routes.stream);
      addTearDown(() async {
        await cubit.close();
        await routes.close();
      });
      final loaded = cubit.stream.firstWhere(
        (state) => state.points.isNotEmpty,
      );
      routes.add(const [LatLng(1, 2)]);
      await loaded;
      cubit.recenter();
      expect(cubit.state.recenterVersion, 1);
      expect(cubit.state.points, const [LatLng(1, 2)]);
      final cleared = cubit.stream.firstWhere((state) => state.points.isEmpty);
      routes.add(const []);
      expect((await cleared).recenterVersion, 1);
    },
  );
}
