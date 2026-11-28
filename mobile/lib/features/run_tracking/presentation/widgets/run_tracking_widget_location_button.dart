import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_route_map.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';

class RunLocationButton extends StatefulWidget {
  final AppColors colors;
  const RunLocationButton({required this.colors});

  @override
  State<RunLocationButton> createState() => RunLocationButtonState();
}

class RunLocationButtonState extends State<RunLocationButton> {
  bool _isFetching = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 12),
        child: FloatingActionButton(
          heroTag: 'manual_location',
          mini: true,
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: widget.colors.surface.withValues(alpha: 0.45),
          onPressed: _isFetching
              ? null
              : () async {
                  setState(() => _isFetching = true);
                  context.read<HapticsCubit>().lightImpact();
                  // 1️⃣ Signal the map to re-center immediately on the currently
                  //    known position — this works even if coordinates haven't
                  //    changed (user panned away and wants to come back).
                  context.read<RunRouteMapCubit>().recenter();
                  try {
                    // 2️⃣ Also fetch a fresh GPS fix so the position updates if the
                    //    user has moved since the last known fix. force=true bypasses
                    //    the "already have position" guard in fetchInitialLocation().
                    await context.read<RunTrackerCubit>().fetchInitialLocation(
                      force: true,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not fetch location. Check GPS is enabled.',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isFetching = false);
                  }
                },
          child: _isFetching
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colors.accent,
                  ),
                )
              : Icon(Icons.gps_fixed, color: widget.colors.accent),
        ),
      ),
    );
  }
}
