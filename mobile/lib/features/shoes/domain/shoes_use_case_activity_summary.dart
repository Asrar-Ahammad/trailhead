import 'dart:math' as math;

typedef ShoeActivity = ({double distanceMeters, int durationSeconds});
typedef ShoeActivitySummary = ({
  int count,
  double longestMeters,
  int durationSeconds,
});

ShoeActivitySummary summarizeShoeActivity(Iterable<ShoeActivity> activities) {
  var count = 0;
  var longest = 0.0;
  var duration = 0;
  for (final activity in activities) {
    count++;
    longest = math.max(longest, activity.distanceMeters);
    duration += activity.durationSeconds;
  }
  return (count: count, longestMeters: longest, durationSeconds: duration);
}
