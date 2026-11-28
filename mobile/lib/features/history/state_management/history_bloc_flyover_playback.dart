import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/flyover_timeline_model.dart';

enum FlyoverCameraMode {
  perspective3D, // 3D forward perspective, North-up (upright text, never inverted)
  chase3D, // 3D forward perspective, auto-heading aligned with travel vector
  topDown2D, // Classic 2D flat top-down, North-up
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

typedef FlyoverAction = void Function(Emitter<FlyoverPlaybackState> emit);

class FlyoverPlaybackBloc extends Bloc<FlyoverAction, FlyoverPlaybackState> {
  final Future<void> Function()? _playToggleSound;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _lastMicroseconds = 0;

  static const List<double> availableSpeeds = [1.0, 2.0, 5.0, 10.0];

  FlyoverPlaybackBloc({
    required FlyoverTimeline timeline,
    Future<void> Function()? playToggleSound,
  }) : _playToggleSound = playToggleSound,
       super(
         FlyoverPlaybackState(
           timeline: timeline,
           isPlaying: false,
           progress: 0.0,
           speedMultiplier: 1.0,
           cameraMode: FlyoverCameraMode.perspective3D,
           currentSample: timeline.sampleAt(0.0),
           baseDurationSeconds: _calculateBaseDuration(timeline),
         ),
       ) {
    on<FlyoverAction>((event, emit) => event(emit));
  }

  static double _calculateBaseDuration(FlyoverTimeline timeline) {
    if (timeline.totalDistanceM <= 0) return 25.0;
    // Dynamic cinematic length: 20s minimum, up to 45s for long runs
    final km = timeline.totalDistanceM / 1000.0;
    final dur = 20.0 + (km * 2.5);
    return dur.clamp(20.0, 45.0);
  }

  void play() => add(_play);
  void pause() => add(_pause);
  void togglePlay() =>
      add((emit) => state.isPlaying ? _pause(emit) : _play(emit));
  void seek(double progress) => add((emit) => _seek(progress, emit));
  void restart() => add((emit) {
    _seek(0, emit);
    _play(emit);
  });

  void _play(Emitter<FlyoverPlaybackState> emit) {
    if (state.isPlaying) return;
    if (state.progress >= 1) _seek(0, emit);
    _stopwatch.reset();
    _stopwatch.start();
    _lastMicroseconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), _onTick);
    emit(state.copyWith(isPlaying: true));
  }

  void _pause(Emitter<FlyoverPlaybackState> emit) {
    if (!state.isPlaying) return;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    emit(state.copyWith(isPlaying: false));
  }

  void _seek(double progress, Emitter<FlyoverPlaybackState> emit) {
    final clamped = progress.clamp(0.0, 1.0);
    emit(
      state.copyWith(
        progress: clamped,
        currentSample: state.timeline.sampleAt(clamped),
      ),
    );
  }

  void cycleSpeed() => add((emit) {
    final current = availableSpeeds.indexOf(state.speedMultiplier);
    emit(
      state.copyWith(
        speedMultiplier:
            availableSpeeds[(current + 1) % availableSpeeds.length],
      ),
    );
  });

  void setCameraMode(FlyoverCameraMode mode) => add((emit) {
    _playToggleSound?.call();
    emit(state.copyWith(cameraMode: mode));
  });

  void toggleTelemetry() => add((emit) {
    _playToggleSound?.call();
    emit(state.copyWith(isTelemetryVisible: !state.isTelemetryVisible));
  });
  void _onTick(Timer timer) => add((emit) {
    if (!state.isPlaying) return;
    final currentMicros = _stopwatch.elapsedMicroseconds;
    final elapsed = (currentMicros - _lastMicroseconds) / 1000000.0;
    _lastMicroseconds = currentMicros;
    final progress =
        state.progress +
        elapsed * state.speedMultiplier / state.baseDurationSeconds;
    if (progress >= 1) _pause(emit);
    _seek(progress, emit);
  });

  @override
  Future<void> close() async {
    _timer?.cancel();
    _stopwatch.stop();
    await super.close();
    _timer?.cancel();
    _stopwatch.stop();
  }
}
