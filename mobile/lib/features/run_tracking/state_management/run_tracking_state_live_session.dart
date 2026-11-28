import 'package:geolocator/geolocator.dart';

class RunTrackerState {
  final String status; // 'idle', 'running', 'paused', 'stopped'
  final String? clientRunId;
  final double distanceM;
  final int durationS;
  final int stepCount;
  final bool gpsWeak;
  final bool permissionsGranted;
  final bool permissionsChecked;
  final int? targetPaceSPerKm;
  final int? currentSplitPaceSPerKm;
  final Position? initialPosition;
  final String activityType; // "run" or "walk"
  final String? selectedShoeId;
  final int currentCadence;
  final int caloriesKcal;

  RunTrackerState({
    required this.status,
    this.clientRunId,
    this.distanceM = 0.0,
    this.durationS = 0,
    this.stepCount = 0,
    this.gpsWeak = false,
    this.permissionsGranted = false,
    this.permissionsChecked = true,
    this.targetPaceSPerKm,
    this.currentSplitPaceSPerKm,
    this.initialPosition,
    this.activityType = 'run',
    this.selectedShoeId,
    this.currentCadence = 0,
    this.caloriesKcal = 0,
  });

  RunTrackerState copyWith({
    String? status,
    String? clientRunId,
    double? distanceM,
    int? durationS,
    int? stepCount,
    bool? gpsWeak,
    bool? permissionsGranted,
    bool? permissionsChecked,
    int? targetPaceSPerKm,
    int? currentSplitPaceSPerKm,
    Position? initialPosition,
    String? activityType,
    String? selectedShoeId,
    bool clearSelectedShoe = false,
    int? currentCadence,
    int? caloriesKcal,
  }) {
    return RunTrackerState(
      status: status ?? this.status,
      clientRunId: clientRunId ?? this.clientRunId,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      stepCount: stepCount ?? this.stepCount,
      gpsWeak: gpsWeak ?? this.gpsWeak,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      permissionsChecked: permissionsChecked ?? this.permissionsChecked,
      targetPaceSPerKm: targetPaceSPerKm ?? this.targetPaceSPerKm,
      currentSplitPaceSPerKm:
          currentSplitPaceSPerKm ?? this.currentSplitPaceSPerKm,
      initialPosition: initialPosition ?? this.initialPosition,
      activityType: activityType ?? this.activityType,
      selectedShoeId: clearSelectedShoe
          ? null
          : (selectedShoeId ?? this.selectedShoeId),
      currentCadence: currentCadence ?? this.currentCadence,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    );
  }
}
