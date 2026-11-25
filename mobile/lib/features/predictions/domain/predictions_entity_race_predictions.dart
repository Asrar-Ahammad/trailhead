typedef PredictionRun = ({double distanceMeters, int durationSeconds});

class RaceEstimate {
  const RaceEstimate(this.label, this.distanceMeters, this.seconds);

  final String label;
  final double distanceMeters;
  final double seconds;
}

class RacePredictions {
  const RacePredictions({required this.estimates, required this.coachAdvice});

  final List<RaceEstimate> estimates;
  final String coachAdvice;
}
