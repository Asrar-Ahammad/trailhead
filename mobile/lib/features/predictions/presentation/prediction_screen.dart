import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../application/prediction_service.dart';
import '../../../shared/state_management/async_value.dart';
import '../../../shared/state_management/local/async_resource_bloc.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AsyncResourceBloc<Map<String, dynamic>>()
        ..add(LoadResource(() => GetIt.instance<PredictionService>().getPredictions())),
      child: BlocBuilder<AsyncResourceBloc<Map<String, dynamic>>, AsyncValue<Map<String, dynamic>>>(
        builder: (context, predictionsAsync) {
          final colors = Theme.of(context).extension<AppColors>()!;
          return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('RACE PREDICTOR', style: AppTextStyles.retroLabelLarge(color: colors.textPrimary).copyWith(fontSize: 20)),
        backgroundColor: colors.surface.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: predictionsAsync.when(
        data: (data) {
          final predictions = data['predictions'] as List<dynamic>;
          final aiReasoning = data['aiReasoning'] as String;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.1),
                    border: Border.all(color: colors.accent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.robot, color: colors.accent, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COACH AI SAYS:', style: AppTextStyles.labelCaps(color: colors.accent)),
                            const SizedBox(height: 4),
                            Text(
                              aiReasoning,
                              style: AppTextStyles.bodyMedium(color: colors.textPrimary).copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('ESTIMATED TIMES', style: AppTextStyles.retroLabel(color: colors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                ...predictions.map((p) => _buildPredictionRow(p['distance'], p['timeStr'], colors)).toList(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '* Calculated using the Peter Riegel formula based on your longest recent run. Sprint times (100m-400m) are extrapolated and may be wildly inaccurate!',
                  style: AppTextStyles.bodyMedium(color: colors.textDisabled).copyWith(fontSize: 12),
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: RetroLoadingIndicator(text: 'PREDICTING RACE')),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.warningCircle, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text('Cannot predict times.', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Make sure you have logged at least one run first!',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
          );
        },
      ),
    );
  }

  Widget _buildPredictionRow(String distance, String time, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(distance, style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
          Text(time, style: AppTextStyles.displayMedium(color: colors.accent).copyWith(fontSize: 24)),
        ],
      ),
    );
  }
}
