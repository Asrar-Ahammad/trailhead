import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/flyover_timeline_model.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';

enum FlyoverCameraMode {
  perspective3D, // 3D forward perspective, North-up (upright text, never inverted)
  chase3D,       // 3D forward perspective, auto-heading aligned with travel vector
  topDown2D,     // Classic 2D flat top-down, North-up
}

class FlyoverPlaybackState {
  final FlyoverTimeline timeline;
  final bool isPlaying;
  final double progress; // 0.0 to 1.0
  final double speedMultiplier; // 1.0, 2.0, 5.0, 10.0, etc.
  final FlyoverCameraMode cameraMode;
  final FlyoverSample currentSample;
  final bool isTelemetryVisible;
  final double baseDurationSeconds; // Total duration to complete playback at 1x

  const FlyoverPlaybackState({
    required this.timeline,
    required this.isPlaying,
    required this.progress,
    required this.speedMultiplier,
    required this.cameraMode,
    required this.currentSample,
    this.isTelemetryVisible = true,
    this.baseDurationSeconds = 30.0,
  });

  FlyoverPlaybackState copyWith({
    FlyoverTimeline? timeline,
    bool? isPlaying,
    double? progress,
    double? speedMultiplier,
    FlyoverCameraMode? cameraMode,
    FlyoverSample? currentSample,
    bool? isTelemetryVisible,
    double? baseDurationSeconds,
  }) {
    return FlyoverPlaybackState(
      timeline: timeline ?? this.timeline,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      cameraMode: cameraMode ?? this.cameraMode,
      currentSample: currentSample ?? this.currentSample,
      isTelemetryVisible: isTelemetryVisible ?? this.isTelemetryVisible,
      baseDurationSeconds: baseDurationSeconds ?? this.baseDurationSeconds,
    );
  }
}

class FlyoverPlaybackNotifier extends StateNotifier<FlyoverPlaybackState> {
  final SoundService? _soundService;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _lastMicroseconds = 0;

  static const List<double> availableSpeeds = [1.0, 2.0, 5.0, 10.0];

  FlyoverPlaybackNotifier({
    required FlyoverTimeline timeline,
    SoundService? soundService,
  })  : _soundService = soundService,
        super(FlyoverPlaybackState(
          timeline: timeline,
          isPlaying: false,
          progress: 0.0,
          speedMultiplier: 1.0,
          cameraMode: FlyoverCameraMode.perspective3D,
          currentSample: timeline.sampleAt(0.0),
          baseDurationSeconds: _calculateBaseDuration(timeline),
        ));

  static double _calculateBaseDuration(FlyoverTimeline timeline) {
    if (timeline.totalDistanceM <= 0) return 25.0;
    // Dynamic cinematic length: 20s minimum, up to 45s for long runs
    final km = timeline.totalDistanceM / 1000.0;
    final dur = 20.0 + (km * 2.5);
    return dur.clamp(20.0, 45.0);
  }

  void play() {
    if (state.isPlaying) return;
    if (state.progress >= 1.0) {
      seek(0.0);
    }
    _stopwatch.reset();
    _stopwatch.start();
    _lastMicroseconds = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), _onTick);

    state = state.copyWith(isPlaying: true);
  }

  void pause() {
    if (!state.isPlaying) return;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isPlaying: false);
  }

  void togglePlay() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seek(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    final sample = state.timeline.sampleAt(clamped);
    state = state.copyWith(
      progress: clamped,
      currentSample: sample,
    );
  }

  void cycleSpeed() {
    final curIndex = availableSpeeds.indexOf(state.speedMultiplier);
    final nextIndex = (curIndex + 1) % availableSpeeds.length;
    final nextSpeed = availableSpeeds[nextIndex];
    state = state.copyWith(speedMultiplier: nextSpeed);
  }

  void setCameraMode(FlyoverCameraMode mode) {
    _soundService?.playToggleSwitch();
    state = state.copyWith(cameraMode: mode);
  }

  void toggleTelemetry() {
    _soundService?.playToggleSwitch();
    state = state.copyWith(isTelemetryVisible: !state.isTelemetryVisible);
  }

  void restart() {
    seek(0.0);
    play();
  }

  void _onTick(Timer timer) {
    final currentMicros = _stopwatch.elapsedMicroseconds;
    final deltaSec = (currentMicros - _lastMicroseconds) / 1000000.0;
    _lastMicroseconds = currentMicros;

    final progressDelta = (deltaSec * state.speedMultiplier) / state.baseDurationSeconds;
    final nextProgress = state.progress + progressDelta;

    if (nextProgress >= 1.0) {
      // Completed playback
      pause();
      seek(1.0);
    } else {
      seek(nextProgress);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}

/// Factory provider for flyover playback controller given a [FlyoverTimeline].
final flyoverPlaybackProvider = StateNotifierProvider.autoDispose
    .family<FlyoverPlaybackNotifier, FlyoverPlaybackState, FlyoverTimeline>((ref, timeline) {
  final soundService = ref.watch(soundServiceProvider);
  return FlyoverPlaybackNotifier(
    timeline: timeline,
    soundService: soundService,
  );
});
