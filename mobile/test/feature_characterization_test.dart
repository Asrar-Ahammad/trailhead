import 'package:trailhead_mobile/features/onboarding/data/onboarding_repository_implementation_completion.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trailhead_mobile/features/ai/domain/ai_config.dart';
import 'package:trailhead_mobile/features/ai/domain/ai_repository_configuration.dart';
import 'package:trailhead_mobile/features/audio/domain/audio_repository_ui_sounds.dart';
import 'package:trailhead_mobile/features/audio/domain/audio_use_case_play_ui_sound.dart';
import 'package:trailhead_mobile/features/chat/domain/chat_entity_coach_conversation.dart';
import 'package:trailhead_mobile/features/chat/domain/chat_repository_coach_conversation.dart';
import 'package:trailhead_mobile/features/chat/domain/chat_use_case_coach_conversation.dart';
import 'package:trailhead_mobile/features/chat/state_management/chat_bloc_coach_conversation.dart';
import 'package:trailhead_mobile/features/data_management/domain/data_management_repository_backups.dart';
import 'package:trailhead_mobile/features/data_management/domain/data_management_use_case_name_exports.dart';
import 'package:trailhead_mobile/features/data_management/state_management/data_management_bloc_backups.dart';
import 'package:trailhead_mobile/features/haptics/domain/haptics_repository_feedback.dart';
import 'package:trailhead_mobile/features/goals/domain/goals_use_case_calculate_progress.dart';
import 'package:trailhead_mobile/features/haptics/domain/haptics_use_case_play_feedback.dart';
import 'package:trailhead_mobile/features/history/domain/entities/manual_run.dart';
import 'package:trailhead_mobile/features/history/domain/entities/parsed_run_log.dart';
import 'package:trailhead_mobile/features/history/domain/repositories/manual_run_repository.dart';
import 'package:trailhead_mobile/features/history/domain/repositories/run_log_parser_repository.dart';
import 'package:trailhead_mobile/features/history/domain/use_cases/parse_manual_run_log.dart';
import 'package:trailhead_mobile/features/history/domain/use_cases/save_manual_run.dart';
import 'package:trailhead_mobile/features/history/state_management/manual_entry_bloc.dart';
import 'package:trailhead_mobile/features/navigation/domain/navigation_entity_main_tab.dart';
import 'package:trailhead_mobile/features/navigation/domain/navigation_use_case_confirm_exit.dart';
import 'package:trailhead_mobile/features/predictions/domain/predictions_entity_race_predictions.dart';
import 'package:trailhead_mobile/features/predictions/domain/predictions_repository_race_predictions.dart';
import 'package:trailhead_mobile/features/predictions/domain/predictions_use_case_load_race_predictions.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/state_management/global/ai_config_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/state_management/global/navigation_cubit_main_tab.dart';
import 'package:trailhead_mobile/shared/state_management/global/onboarding_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/global/theme_mode_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/local/async_resource_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Goal progress uses the current metrics and avoids counting steps twice',
    () {
      final now = DateTime(2026, 1, 22, 12);
      final activities = <GoalActivity>[
        (
          startedAt: now,
          steps: 2000,
          distanceMeters: 5000,
          durationSeconds: 1800,
        ),
        (
          startedAt: DateTime(2026, 1, 21),
          steps: 1000,
          distanceMeters: 1000,
          durationSeconds: 600,
        ),
        (
          startedAt: DateTime(2025, 12, 31),
          steps: 8000,
          distanceMeters: 6000,
          durationSeconds: 3600,
        ),
      ];
      expect(
        calculateGoalProgress(
          activities: activities,
          metrics: (daily: 'steps', monthly: 'distance'),
          now: now,
          dailySteps: 3000,
        ),
        (dailyProgress: 3000.0, monthlyProgress: 6.0),
      );
      expect(
        calculateGoalProgress(
          activities: activities,
          metrics: (daily: 'distance', monthly: 'duration'),
          now: now,
          dailySteps: 3000,
        ),
        (dailyProgress: 5.0, monthlyProgress: 40.0),
      );
    },
  );

  test(
    'Onboarding and theme Cubits persist the values used on restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final onboarding = OnboardingCubit(OnboardingCompletionPreferences(preferences));
      final theme = ThemeModeCubit(
        preferences: preferences,
        initialMode: ThemeMode.system,
      );
      addTearDown(onboarding.close);
      addTearDown(theme.close);

      await onboarding.completeOnboarding();
      expect(onboarding.state, isTrue);
      expect(preferences.getBool('seen_onboarding'), isTrue);
      await onboarding.resetOnboarding();
      expect(preferences.getBool('seen_onboarding'), isFalse);
      await theme.setMode(ThemeMode.dark);
      expect(theme.state, ThemeMode.dark);
      expect(preferences.getString('themeMode'), 'dark');
    },
  );

  test(
    'Predictions use the longest valid run and retain offline estimates',
    () async {
      final repository = _Predictions([
        (distanceMeters: 10000, durationSeconds: 3000),
        (distanceMeters: 20000, durationSeconds: 0),
        (distanceMeters: 5000, durationSeconds: 1200),
      ]);
      final predictions = (await LoadRacePredictions(repository)())!;
      expect(repository.limit, 10);
      expect(repository.baseline, (
        distanceMeters: 10000.0,
        durationSeconds: 3000,
      ));
      expect(predictions.estimates.map((estimate) => estimate.label), [
        '100m',
        '200m',
        '400m',
        '5K',
        '10K',
        'Half Marathon',
        'Marathon',
      ]);
      expect(predictions.estimates[4].seconds, 3000);
      expect(predictions.coachAdvice, 'Keep training to achieve these times!');
    },
  );

  test('Predictions skip the coach request if no run can be used', () async {
    final repository = _Predictions([
      (distanceMeters: 0, durationSeconds: 300),
    ]);
    expect(await LoadRacePredictions(repository)(), isNull);
    expect(repository.baseline, isNull);
  });

  test('Haptics uses the saved preference for all feedback', () async {
    final repository = _Haptics();
    final cubit = HapticsCubit(repository, PlayHapticFeedback(repository));
    addTearDown(cubit.close);
    await cubit.heavyImpact();
    await cubit.setEnabled(true);
    await cubit.heavyImpact();
    await cubit.setEnabled(false);
    await cubit.selectionClick();
    expect(repository.effects, [HapticEffect.light, HapticEffect.heavy]);
    expect(repository.isEnabled, isFalse);
  });

  test(
    'Audio uses one preference for navigation, action and alert cues',
    () async {
      final repository = _Audio();
      final cubit = AudioCubit(repository, PlayUiSound(repository));
      addTearDown(cubit.close);
      await cubit.playSystemBack();
      await cubit.setEnabled(true);
      await cubit.playSystemBack();
      await cubit.playButtonTap();
      await cubit.playSuccess();
      repository.isEnabled = false;
      cubit.reloadPreference();
      await cubit.playPrNew();
      expect(repository.cues, [
        AudioCue.toggleSwitch,
        AudioCue.systemBack,
        AudioCue.buttonTap,
        AudioCue.prNew,
      ]);
    },
  );

  test(
    'Chat sends recent activity as hidden context and streams the reply',
    () async {
      final repository = _Chat(['Good', ' work']);
      final bloc = ChatBloc(ChatCoachConversation(repository));
      addTearDown(bloc.close);
      final emitted = bloc.stream.take(4).toList();
      bloc.add(const ChatMessageSent('  How did I do?  ', useMiles: true));
      final states = await emitted;
      expect(states.first.isReplying, isTrue);
      expect(states[1].messages.last.text, 'Good');
      expect(states.last.isReplying, isFalse);
      expect(states.last.messages, [
        (role: ChatRole.user, text: 'How did I do?'),
        (role: ChatRole.assistant, text: 'Good work'),
      ]);
      expect(repository.history.first.role, ChatRole.system);
      expect(repository.history.first.text, contains('3.11 mi in 25 mins.'));
      expect(repository.fallbackCalls, 0);
    },
  );

  test('Chat falls back once when the stream is empty', () async {
    final repository = _Chat([' ']);
    final reply = await ChatCoachConversation(repository).reply([]).toList();
    expect(reply, ['Fallback']);
    expect(repository.fallbackCalls, 1);
  });

  test(
    'Data Management preserves export names and explicit restore mode',
    () async {
      expect(
        backupFileName(DateTime(2026, 2, 3, 4, 5)),
        'trailhead_backup_2026-02-03_0405.json',
      );
      expect(
        routeExportFileName(
          startTime: DateTime(2026, 2, 3),
          distanceMeters: 5000,
          title: 'Hill & track',
        ),
        'trailhead_Hill___track_5.0km_20260203.gpx',
      );

      final repository = _Backups();
      final bloc = DataManagementBloc(repository, onPreferencesRestored: () {});
      addTearDown(bloc.close);
      final completed = bloc.stream
          .where((state) => state is BackupRestored)
          .first;
      bloc.add(const RestoreBackup('legacy.json', BackupRestoreMode.overwrite));
      expect((await completed as BackupRestored).backup, (runs: 3, shoes: 1));
      expect(repository.restore, (
        path: 'legacy.json',
        mode: BackupRestoreMode.overwrite,
      ));
    },
  );

  test(
    'Navigation publishes named tab transitions and confirms a timed exit',
    () async {
      final navigator = NavigationCubit();
      addTearDown(navigator.close);
      final events = navigator.stream.take(2).toList();
      navigator.selectTab(MainTab.record);
      navigator.selectTab(MainTab.record);
      navigator.selectTab(MainTab.home);
      expect(await events, [MainTab.record, MainTab.home]);

      final confirmExit = ConfirmAppExit();
      final now = DateTime.utc(2026, 1, 1);
      expect(confirmExit(now), isFalse);
      expect(confirmExit(now.add(const Duration(seconds: 3))), isFalse);
      expect(confirmExit(now.add(const Duration(seconds: 5))), isTrue);
    },
  );

  testWidgets('AppNavigator returns typed route results', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await AppNavigator.push(
                  context,
                  AppNavigator.materialPageRoute<bool>(
                    builder: (context) {
                      return TextButton(
                        onPressed: () => AppNavigator.pop(context, true),
                        child: const Text('Confirm'),
                      );
                    },
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  test('Restore refreshes global preferences after Settings closes', () async {
    final repository = _Backups()..pendingRestore = Completer<void>();
    final refreshed = Completer<void>();
    final bloc = DataManagementBloc(
      repository,
      onPreferencesRestored: refreshed.complete,
    );
    final started = bloc.stream.firstWhere(
      (state) => state is DataManagementBusy,
    );
    bloc.add(const RestoreBackup('backup.json', BackupRestoreMode.merge));
    await started;
    final closing = bloc.close();
    repository.pendingRestore!.complete();
    await refreshed.future.timeout(const Duration(seconds: 2));
    await closing;
  });

  test(
    'AI provider change selects a default model and keeps the saved key',
    () async {
      final repository = _AiConfig();
      final cubit = AiConfigCubit(repository);
      addTearDown(cubit.close);
      await cubit.updateConfig(provider: 'gemini');
      expect(repository.saved.model, 'gemini-3.8-flash');
      expect(repository.saved.apiKey, 'example');
    },
  );

  test(
    'AI retries the same preference after transient storage failure',
    () async {
      final repository = _AiConfig()..failNextSave = true;
      final cubit = AiConfigCubit(repository);
      addTearDown(cubit.close);
      await cubit.updateConfig(model: 'gpt-5-mini');
      await cubit.updateConfig(model: 'gpt-5-mini');
      expect(repository.saved.model, 'gpt-5-mini');
    },
  );

  test('Manual entry rejects NaN and infinity without writing a run', () async {
    final repository = _ManualRuns();
    final save = SaveManualRun(repository);
    for (final invalid in ['NaN', 'Infinity', '0', '-1', '']) {
      expect(
        await save(distanceText: invalid, effort: '', conditions: ''),
        ManualRunSaveResult.invalidDistance,
        reason: invalid,
      );
    }
    expect(repository.saved, isEmpty);
  });

  test('Manual entry ignores overlapping save events', () async {
    final repository = _ManualRuns()..pendingWrite = Completer<void>();
    final bloc = ManualEntryBloc(
      ParseManualRunLog(_RunParser()),
      SaveManualRun(repository),
    );
    addTearDown(bloc.close);
    const save = SaveManualEntry(
      distanceText: '5',
      effort: 'easy',
      conditions: '',
    );
    bloc
      ..add(save)
      ..add(save);
    await Future<void>.delayed(Duration.zero);
    repository.pendingWrite!.complete();
    await bloc.close();
    expect(repository.saved, hasLength(1));
  });

  test('Shared resource Bloc emits the typed result of a local load', () async {
    final bloc = AsyncResourceBloc<int>();
    addTearDown(bloc.close);
    final value = bloc.stream.firstWhere((state) => state.hasValue);
    bloc.add(LoadResource(() async => 42));
    expect((await value).valueOrNull, 42);
  });
}

class _Predictions implements PredictionsRepository {
  _Predictions(this.runs);
  final List<PredictionRun> runs;
  PredictionRun? baseline;
  int? limit;

  @override
  Future<List<PredictionRun>> loadRecentRuns({required int limit}) async {
    this.limit = limit;
    return runs;
  }

  @override
  Future<String?> loadCoachAdvice(
    PredictionRun baseline,
    List<RaceEstimate> estimates,
  ) async {
    this.baseline = baseline;
    throw StateError('Offline');
  }
}

class _Haptics implements HapticsRepository {
  @override
  bool isEnabled = false;
  final effects = <HapticEffect>[];

  @override
  Future<bool> setEnabled(bool enabled) async {
    isEnabled = enabled;
    return true;
  }

  @override
  Future<void> play(HapticEffect effect) async => effects.add(effect);
}

class _Audio implements AudioRepository {
  @override
  bool isEnabled = false;
  final cues = <AudioCue>[];

  @override
  Future<bool> setEnabled(bool enabled) async {
    isEnabled = enabled;
    return true;
  }

  @override
  Future<void> play(AudioCue cue) async => cues.add(cue);
}

class _Chat implements ChatRepository {
  _Chat(this.parts);
  final List<String> parts;
  List<ChatMessage> history = [];
  int fallbackCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<List<ChatActivity>> loadRecentActivities({required int limit}) async =>
      [
        (
          type: 'run',
          startTime: DateTime.utc(2026, 1, 1),
          distanceMeters: 5000,
          durationSeconds: 1500,
        ),
      ];

  @override
  Stream<String> streamReply(List<ChatMessage> messages) {
    history = messages;
    return Stream.fromIterable(parts);
  }

  @override
  Future<String?> loadReply(List<ChatMessage> messages) async {
    fallbackCalls++;
    return 'Fallback';
  }
}

class _Backups implements DataManagementRepository {
  ({String path, BackupRestoreMode mode})? restore;
  Completer<void>? pendingRestore;

  @override
  Future<RestoredBackup> restoreBackup(
    String path,
    BackupRestoreMode mode,
  ) async {
    restore = (path: path, mode: mode);
    await pendingRestore?.future;
    return (runs: 3, shoes: 1);
  }

  @override
  Future<BackupFile> exportBackup(BackupDestination destination) async =>
      (path: 'backup.json', name: 'backup.json');

  @override
  Future<int> exportRoutes() async => 2;
}

class _AiConfig implements AiConfigurationRepository {
  AiConfig saved = const AiConfig(
    provider: 'openai',
    model: 'gpt-5',
    apiKey: 'example',
  );
  bool failNextSave = false;

  @override
  AiConfig load() => saved;

  @override
  Future<void> save(AiConfig config) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Storage temporarily unavailable');
    }
    saved = config;
  }
}

class _ManualRuns implements ManualRunRepository {
  final saved = <ManualRun>[];
  Completer<void>? pendingWrite;

  @override
  Future<void> saveManualRun(ManualRun run) async {
    saved.add(run);
    await pendingWrite?.future;
  }
}

class _RunParser implements RunLogParserRepository {
  @override
  Future<ParsedRunLog?> parse(String text) async => null;
}
