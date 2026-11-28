import 'package:trailhead_mobile/features/home/presentation/widgets/home_widget_weather_details.dart';
import 'package:trailhead_mobile/features/weather/domain/weather_repository_current_conditions.dart';
import 'package:trailhead_mobile/features/weather/domain/weather_use_case_pacing.dart';
import 'package:trailhead_mobile/features/history/presentation/share_activity_screen.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/goals/presentation/widgets/goals_widget_target_fields.dart';
import 'package:trailhead_mobile/features/home/presentation/widgets/home_widget_weekly_summary.dart';
import 'package:trailhead_mobile/features/onboarding/presentation/widgets/onboarding_widget_slide.dart';
import 'package:trailhead_mobile/features/onboarding/presentation/widgets/onboarding_widget_tour_previews.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/run_tracking_widget_live_stats.dart';
import 'package:trailhead_mobile/features/run_tracking/presentation/widgets/run_tracking_widget_stop_sheet.dart';
import 'package:trailhead_mobile/features/run_tracking/state_management/run_tracking_state_live_session.dart';
import 'package:trailhead_mobile/features/shoes/domain/shoes_repository_inventory.dart';
import 'package:trailhead_mobile/features/shoes/presentation/widgets/shoes_widget_inventory_card.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/widgets/inset_sheet_body.dart';
import 'package:trailhead_mobile/shared/widgets/shoe_photo.dart';

const colors = AppColors.dark;

Widget layoutHarness(
  Widget child, {
  double scale = 2,
  double keyboardHeight = 0,
}) => MaterialApp(
  theme: ThemeData.dark().copyWith(extensions: const [colors]),
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      size: const Size(320, 480),
      viewInsets: EdgeInsets.only(bottom: keyboardHeight),
    ),
    child: Scaffold(resizeToAvoidBottomInset: false, body: child),
  ),
);

void main() {
  setUpWidgets(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('weekly summary wraps at narrow width with larger text', (
    tester,
  ) async {
    await setUpWidgets(tester);
    await tester.pumpWidget(
      layoutHarness(
        SingleChildScrollView(
          child: HomeWeeklySummary(
            colors: colors,
            useMiles: true,
            summary: (
              distanceKm: 1234.0,
              runCount: 109,
              streakDays: 325,
              chartData: List.filled(7, 1.0),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('325 DAY STREAK'), findsOneWidget);
  });

  testWidgets(
    'tour preview scrolls to reveal its description on short screens',
    (tester) async {
      await setUpWidgets(tester);
      const description =
          'Enable background location to record outdoor activities.';
      await tester.pumpWidget(
        layoutHarness(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 250,
              child: OnboardingSlide(
                colors: colors,
                badge: 'LOCAL-FIRST',
                title: 'READY TO HIT THE ROAD',
                description: description,
                preview: onboardingPermissionsPreview(
                  colors,
                  requesting: false,
                  isGranted: false,
                  onRequest: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text(description));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(description).hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'running, gear, and predictions tour cards wrap at larger text sizes',
    (tester) async {
      await setUpWidgets(tester);
      for (final preview in [
        onboardingTrackingPreview,
        onboardingShoePreview,
        onboardingPredictionsPreview,
      ]) {
        await tester.pumpWidget(
          layoutHarness(
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: preview(colors),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('goal inputs fit narrow sheets above the keyboard', (
    tester,
  ) async {
    await setUpWidgets(tester);
    final target = TextEditingController(text: '10.5');
    addTearDown(target.dispose);
    await tester.pumpWidget(
      layoutHarness(
        InsetSheetBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoalTargetFields(
                metric: 'duration',
                target: target,
                colors: colors,
                onMetricChanged: (_) {},
              ),
              const SizedBox(height: 80),
              const Text('SAVE GOALS'),
            ],
          ),
        ),
        keyboardHeight: 250,
      ),
    );
    await tester.ensureVisible(find.text('SAVE GOALS'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('10.5'), findsOneWidget);
  });

  testWidgets('run metrics and finish sheet remain usable with large text', (
    tester,
  ) async {
    await setUpWidgets(tester);
    final units = DistanceUnitCubit(useMiles: true);
    addTearDown(units.close);
    await tester.pumpWidget(
      layoutHarness(
        BlocProvider.value(
          value: units,
          child: SingleChildScrollView(
            child: RunLiveStats(
              colors: colors,
              trackerState: RunTrackerState(
                status: 'running',
                durationS: 7275,
                distanceM: 35000,
                currentSplitPaceSPerKm: 240,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Split avg. (/mi)'), findsOneWidget);
    expect(find.text('06:26'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      layoutHarness(const RunStopSheet(colors: colors, activityType: 'run')),
    );
    expect(find.text('Finish & Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'share preview keeps the editor controls accessible at large text',
    (tester) async {
      await setUpWidgets(tester);
      final units = DistanceUnitCubit();
      addTearDown(units.close);
      await tester.pumpWidget(
        layoutHarness(
          BlocProvider.value(
            value: units,
            child: ShareActivityScreen(
              run: RunIsar()
                ..distanceM = 42000
                ..durationS = 12345,
              points: const [],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Take Photo'), findsOneWidget);
      await tester.ensureVisible(find.text('ROUTE ACCENT'));
      await tester.pump();
      expect(find.text('ROUTE ACCENT').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('weather details wrap long locality names and scroll to advice', (
    tester,
  ) async {
    await setUpWidgets(tester);
    final pacing = WeatherPacing.forConditions(
      const WeatherConditions(
        temperature: 27,
        windSpeed: 25,
        code: 96,
        isDay: true,
        city: 'Very Long Locality Name Near The Outer Western Suburbs',
      ),
    );
    await tester.pumpWidget(
      layoutHarness(HomeWeatherDetails(colors: colors, data: pacing)),
    );
    await tester.ensureVisible(find.text('COACH ADVICE'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('COACH ADVICE').hitTestable(), findsOneWidget);
  });

  testWidgets('long shoe names leave space for the photo and gear menu', (
    tester,
  ) async {
    await setUpWidgets(tester);
    await tester.pumpWidget(
      layoutHarness(
        const SingleChildScrollView(
          child: ShoeInventoryCard(
            shoe: ShoeGear(
              id: 1,
              name: 'Limited edition long distance training shoe',
              brand: 'Very Long Brand Name',
            ),
            colors: colors,
          ),
        ),
      ),
    );
    expect(find.byType(ShoePhoto), findsOneWidget);
    expect(find.byTooltip('Shoe actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
