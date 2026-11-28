import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import '../domain/flyover_timeline_model.dart';
import '../state_management/history_bloc_flyover_playback.dart';
import 'widgets/flyover_3d_map_view.dart';
import 'widgets/flyover_telemetry_hud.dart';
import 'widgets/flyover_scrubber_controls.dart';
import 'widgets/flyover_export_dialog.dart';

/// Full-screen 3D Route Flyover replay screen for completed activities.
class RunFlyoverScreen extends StatefulWidget {
  final RunIsar run;
  final List<RunPointIsar> points;

  const RunFlyoverScreen({
    super.key,
    required this.run,
    required this.points,
  });

  @override
  State<RunFlyoverScreen> createState() => _RunFlyoverScreenState();
}

class _RunFlyoverScreenState extends State<RunFlyoverScreen> {
  late final FlyoverTimeline _timeline;
  late final FlyoverPlaybackBloc _playback;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final useMiles = context.read<DistanceUnitCubit>().state;
    _timeline = FlyoverTimeline.fromRunPoints(
      widget.points,
      useMiles: useMiles,
      fallbackDurationS: widget.run.durationS?.toDouble(),
      fallbackDistanceM: widget.run.distanceM,
      fallbackAvgPaceSPerKm: widget.run.avgPaceSPerKm,
    );
    _playback = FlyoverPlaybackBloc(
      timeline: _timeline,
      playToggleSound: context.read<AudioCubit>().playToggleSwitch,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Auto-start playback on screen open like Strava Flyover
      _playback.play();
    });
  }

  @override
  void dispose() {
    _playback.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _playback, child: Builder(builder: _buildFlyover),
  );

  Widget _buildFlyover(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;
    final useMiles = context.watch<DistanceUnitCubit>().state;
    final playbackState = context.watch<FlyoverPlaybackBloc>().state;
    final controller = _playback;

    final title = RunFormatUtils.getRunTitle(
      widget.run.title,
      widget.run.startTime,
      activityType: widget.run.activityType ?? 'run',
      distanceM: widget.run.distanceM,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness,
      ),
      child: Scaffold(
        backgroundColor: retroColors.background,
        body: Stack(
          children: [
            // 1. Video recording target: 3D Map + Floating Telemetry HUD
            Positioned.fill(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Flyover3DMapView(
                        timeline: _timeline,
                        playbackState: playbackState,
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 72,
                      left: 16,
                      right: 16,
                      child: FlyoverTelemetryHUD(
                        sample: playbackState.currentSample,
                        useMiles: useMiles,
                        isVisible: playbackState.isTelemetryVisible,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Top Navigation & Activity Bar (Frosted glass header, excluded from video export)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 4,
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    decoration: BoxDecoration(
                      color: retroColors.surface.withValues(alpha: 0.48),
                      border: Border(
                        bottom: BorderSide(
                          color: retroColors.border.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(PhosphorIcons.arrowLeft, color: retroColors.textPrimary, size: 22),
                          onPressed: () => AppNavigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: retroColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: retroColors.accent.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '3D FLYOVER',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: retroColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: retroColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // HUD Toggle Button
                        IconButton(
                          icon: Icon(
                            playbackState.isTelemetryVisible
                                ? PhosphorIcons.chartBarFill
                                : PhosphorIcons.chartBar,
                            color: playbackState.isTelemetryVisible
                                ? retroColors.accent
                                : retroColors.textSecondary,
                            size: 22,
                          ),
                          tooltip: 'Toggle Telemetry HUD',
                          onPressed: () => controller.toggleTelemetry(),
                        ),
                        // Share Video Button
                        IconButton(
                          icon: Icon(
                            PhosphorIcons.shareNetwork,
                            color: retroColors.accent,
                            size: 22,
                          ),
                          tooltip: 'Share Flyover Video',
                          onPressed: () {
                            controller.pause();
                            FlyoverExportDialog.show(
                              context: context,
                              repaintKey: _repaintKey,
                              controller: controller,
                              run: widget.run,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),


          // 3. Bottom Scrubber & Controls Panel (Excluded from video export)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: FlyoverScrubberControls(
              timeline: _timeline,
              playbackState: playbackState,
              controller: controller,
            ),
          ),
        ],
      ),
    ),
  );
}
}
