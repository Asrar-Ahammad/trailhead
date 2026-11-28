typedef RecapMetrics = ({double calories, double cadence, double stride});

RecapMetrics recapMetrics({
  required double distanceM,
  double? calories,
  double? cadence,
  double? stride,
}) => (
  calories: calories ?? (distanceM / 1000 * 65),
  cadence: cadence ?? 160,
  stride: stride ?? 1.1,
);
