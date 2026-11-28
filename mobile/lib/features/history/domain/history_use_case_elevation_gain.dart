double? calculateElevationGain(List<double?> elevations) {
  if (elevations.length < 3) return null;
  double gain = 0.0;
  for (int i = 2; i < elevations.length; i++) {
    final alt0 = elevations[i - 2] ?? 0.0;
    final alt1 = elevations[i - 1] ?? 0.0;
    final alt2 = elevations[i] ?? 0.0;
    final smoothedPrev = (alt0 + alt1) / 2.0;
    final smoothedCurr = (alt1 + alt2) / 2.0;
    final diff = smoothedCurr - smoothedPrev;
    if (diff > 0.3) {
      gain += diff;
    }
  }
  return gain > 0 ? gain : null;
}
