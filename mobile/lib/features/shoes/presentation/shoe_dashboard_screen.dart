import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';
import 'package:trailhead_mobile/shared/widgets/shoe_photo.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import '../../../shared/state_management/global/shoes_cubit_inventory.dart';
import '../domain/shoes_repository_inventory.dart';
import '../state_management/shoes_bloc_activity.dart';
import '../state_management/shoes_bloc_edit_gear.dart';
import 'shoes_dialog_edit_gear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import '../../you/presentation/widgets/activity_card.dart';

class ShoeDashboardScreen extends StatelessWidget {
  const ShoeDashboardScreen({super.key, required this.shoe});
  final ShoeGear shoe;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            context.read<CreateShoeActivityBloc>()(shoe.clientShoeId),
      ),
      BlocProvider(create: (_) => context.read<CreateShoeEditBloc>()()),
    ],
    child: _ShoeDashboardContent(shoe),
  );
}

class _ShoeDashboardContent extends StatelessWidget {
  const _ShoeDashboardContent(this.initialShoe);
  final ShoeGear initialShoe;

  Future<void> _pickImage(BuildContext context, int? id) async {
    if (id == null) return;
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (photo != null && context.mounted) {
        context.read<ShoeEditBloc>().add(SetShoePhoto(id, photo.path));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo picker.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final runsAsync = context.watch<ShoeActivityBloc>().state;
    final inventory = context.watch<ShoesCubit>().state.valueOrNull;
    final shoe =
        inventory?.where((shoe) => shoe.id == initialShoe.id).firstOrNull ??
        initialShoe;
    final processing = context.select((ShoeEditBloc bloc) => bloc.state.busy);
    final useMiles = context.watch<DistanceUnitCubit>().state;

    return BlocListener<ShoeEditBloc, ShoeEditState>(
      listener: (context, state) {
        if (state.error case final error?) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowLeft, color: colors.textPrimary),
            onPressed: () => AppNavigator.pop(context),
          ),
          title: Text(
            shoe.name ?? 'Gear Stats',
            style: AppTextStyles.headline(color: colors.textPrimary),
          ),
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.pencilSimple, color: colors.textPrimary),
              tooltip: 'Edit Shoe',
              onPressed: () => showShoeEditor(context, shoe: shoe),
            ),
          ],
        ),
        body: runsAsync.when(
          data: (data) {
            final runs = data.runs;
            final totalRuns = data.summary.count;
            final maxDistanceM = data.summary.longestMeters;
            final displayDistance = RunFormatUtils.distanceInUnit(
              shoe.distanceM,
              useMiles,
            );
            final displayMaxDist = RunFormatUtils.distanceInUnit(
              maxDistanceM,
              useMiles,
            );
            final distUnit = RunFormatUtils.getUnitString(useMiles);
            final formattedAvgPace = RunFormatUtils.formatPace(
              shoe.distanceM,
              data.summary.durationSeconds,
              useMiles,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Info
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Hero(
                          tag: 'shoe_image_${shoe.clientShoeId ?? shoe.id}',
                          child: ShoePhoto(
                            source: shoe.imageUrl,
                            size: 150,
                            color: colors.accent,
                            background: colors.surfaceRaised,
                            radius: 12,
                            iconSize: 64,
                          ),
                        ),
                        if (!processing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _pickImage(context, shoe.id),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.background,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  PhosphorIcons.camera,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (processing)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Removing background...',
                              style: AppTextStyles.label(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          shoe.name ?? 'Unknown Shoe',
                          style: AppTextStyles.displayMedium(
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => showShoeEditor(context, shoe: shoe),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.pencilSimple,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (shoe.brand != null && shoe.brand!.isNotEmpty)
                    Center(
                      child: Text(
                        shoe.brand!,
                        style: AppTextStyles.bodyLarge(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Stat Grid
                  AdaptiveColumns(
                    maxColumns: 2,
                    minColumnWidth: 145,
                    spacing: 16,
                    children: [
                      _buildStatCard(
                        colors,
                        'TOTAL DISTANCE',
                        '${displayDistance.toStringAsFixed(1)} $distUnit',
                      ),
                      _buildStatCard(colors, 'TOTAL RUNS', '$totalRuns'),
                      _buildStatCard(
                        colors,
                        'AVERAGE PACE',
                        '$formattedAvgPace / $distUnit',
                      ),
                      _buildStatCard(
                        colors,
                        'LONGEST RUN',
                        '${displayMaxDist.toStringAsFixed(1)} $distUnit',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'RECENT ACTIVITY',
                    style: AppTextStyles.labelCaps(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  if (runs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No runs tracked with this gear yet.',
                          style: AppTextStyles.bodyMedium(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...runs.take(5).map((run) => ActivityCard(run: run)),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error loading stats: $err',
              style: TextStyle(color: colors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(AppColors colors, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.labelCaps(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headline(color: colors.textPrimary)),
        ],
      ),
    );
  }
}
