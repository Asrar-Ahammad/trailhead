import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import '../data/models/run_isar.dart';
import '../../ai/application/ai_client.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';

class RunAnalysisService {
  final Isar _isar;
  final SharedPreferences _preferences;
  final AiConfigCubit _aiConfigCubit;

  RunAnalysisService({required Isar isar, required SharedPreferences preferences, required AiConfigCubit aiConfigCubit})
      : _isar = isar,
        _preferences = preferences,
        _aiConfigCubit = aiConfigCubit;

  /// Computes a local performance summary based on Isar run data.
  Future<void> refreshPerformanceSummary() async {
    try {
      final runs = await _isar.runIsars.filter().statusEqualTo('completed').findAll();
      if (runs.isEmpty) return;

      double totalDistanceKm = 0;
      int totalDurationS = 0;
      for (final run in runs) {
        totalDistanceKm += (run.distanceM ?? 0) / 1000.0;
        totalDurationS += run.durationS ?? 0;
      }

      final avgPace = totalDistanceKm > 0 ? totalDurationS / totalDistanceKm : 0.0;

      final summary = {
        'totalRuns': runs.length,
        'totalDistanceKm': totalDistanceKm.toStringAsFixed(2),
        'avgPaceSPerKm': avgPace,
        'trendMessage': runs.length > 1 ? 'Your weekly distance is increasing!' : 'First runs complete! Keep it up.',
        'topStats': [
          {'label': 'Longest Run', 'value': '${(runs.map((r) => r.distanceM ?? 0).reduce((a, b) => a > b ? a : b) / 1000.0).toStringAsFixed(2)} km', 'detail': ''}
        ]
      };

      await _preferences.setString('user_performance_summary', jsonEncode(summary));
    } catch (e) {
      debugPrint('[RunAnalysisService] Failed to refresh performance summary: $e');
    }
  }

  /// Generates AI analysis for a completed run locally.
  Future<void> generateAnalysisForRun(RunIsar activeRun) async {
    final aiConfig = _aiConfigCubit.state;
    if (!aiConfig.isConfigured) return;

    try {
      await refreshPerformanceSummary();

      final summaryString = _preferences.getString('user_performance_summary') ?? '{}';
      
      final systemPrompt = 'You are an expert, encouraging AI running coach. '
          'Your job is to provide a detailed 4-6 sentence analysis of the user\'s latest run. '
          'Format your response as a short opening paragraph (2-3 sentences) followed by 2-3 bullet points using "•". '
          'Do not use markdown bold/italic formatting, and do not use emojis.';

      final userPrompt = 'Historical Performance Profile:\n$summaryString\n\n'
          'Latest Run Stats:\n'
          'Distance: ${(activeRun.distanceM ?? 0) / 1000} km\n'
          'Duration: ${(activeRun.durationS ?? 0) / 60} mins\n'
          'Avg Pace: ${activeRun.avgPaceSPerKm ?? 0} s/km\n'
          'Cadence: ${activeRun.avgCadenceSpm ?? 0} spm';

      final aiClient = AiClient(aiConfig);
      final reply = await aiClient.chat([
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt}
      ]);

      if (reply != null && reply.isNotEmpty) {
        activeRun.aiAnalysis = reply;
        await _isar.writeTxn(() async {
          await _isar.runIsars.put(activeRun);
        });
      }
    } catch (e) {
      debugPrint('[RunAnalysisService] Failed to generate AI analysis: $e');
    }
  }
}
