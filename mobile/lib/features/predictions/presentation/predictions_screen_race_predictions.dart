import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/state_management/async_value.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';
import 'package:trailhead_mobile/features/predictions/domain/predictions_entity_race_predictions.dart';
import 'package:trailhead_mobile/features/predictions/state_management/predictions_bloc_race_predictions.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final createBloc = context.read<CreatePredictionsBloc>();

    return BlocProvider(
      create: (_) => createBloc()..add(const PredictionsRequested()),
      child: Scaffold(
        backgroundColor: colors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'RACE PREDICTOR',
            style: AppTextStyles.retroLabelLarge(
              color: colors.textPrimary,
            ).copyWith(fontSize: 20),
          ),
          backgroundColor: colors.surface.withValues(alpha: 0.7),
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox.expand(),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => AppNavigator.pop(context),
          ),
        ),
        body: BlocBuilder<PredictionsBloc, AsyncValue<RacePredictions?>>(
          builder: (context, state) => state.when(
            loading: () => const Center(
              child: RetroLoadingIndicator(text: 'PREDICTING RACE'),
            ),
            data: (predictions) => predictions == null
                ? _buildMessage(
                    colors,
                    'Log a run with a distance and duration first.',
                  )
                : _buildPredictions(context, colors, predictions),
            error: (_, _) => _buildMessage(
              colors,
              'Could not load your runs. Try reopening the race predictor.',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictions(
    BuildContext context,
    AppColors colors,
    RacePredictions predictions,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + kToolbarHeight + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            border: Border.all(color: colors.accent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.robot, color: colors.accent, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COACH AI SAYS:',
                      style: AppTextStyles.labelCaps(color: colors.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      predictions.coachAdvice,
                      style: AppTextStyles.bodyMedium(
                        color: colors.textPrimary,
                      ).copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'ESTIMATED TIMES',
          style: AppTextStyles.retroLabel(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final estimate in predictions.estimates)
          _buildEstimateRow(colors, estimate),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Estimates use the Riegel formula and your longest recent valid run. '
          'Sprint times (100–400 m) can be especially inaccurate.',
          style: AppTextStyles.bodyMedium(
            color: colors.textDisabled,
          ).copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEstimateRow(AppColors colors, RaceEstimate estimate) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              estimate.label,
              style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _formatTime(estimate),
            style: AppTextStyles.displayMedium(
              color: colors.accent,
            ).copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  String _formatTime(RaceEstimate estimate) {
    if (estimate.distanceMeters <= 400) {
      return '${estimate.seconds.toStringAsFixed(2)}s';
    }
    final duration = Duration(seconds: estimate.seconds.round());
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    if (duration.inHours == 0) return '${duration.inMinutes}:$seconds';
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
  }

  Widget _buildMessage(AppColors colors, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warningCircle, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Cannot predict times.',
              style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
