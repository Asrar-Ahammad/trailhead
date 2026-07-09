/// Pure formatting utilities for run tracking display values.
/// No widget dependencies — these are plain Dart functions,
/// keeping build() methods strictly presentational.
abstract final class RunFormatUtils {
  /// Formats [totalSeconds] as MM:SS or H:MM:SS.
  static String formatDuration(int totalSeconds) {
    final int hours   = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns current pace as "MM:SS" per km, or "-:--" if insufficient data.
  static String formatPace(double distanceM, int durationS) {
    if (distanceM <= 0 || durationS <= 0) return '-:--';
    final double distanceKm = distanceM / 1000.0;
    final double paceS      = durationS / distanceKm;
    final int paceMin  = (paceS / 60).floor();
    final int paceSec  = (paceS % 60).round();
    return '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')}';
  }

  /// Formats [distanceM] as a km string with 2 decimal places.
  static String formatDistanceKm(double distanceM) {
    return (distanceM / 1000.0).toStringAsFixed(2);
  }

  /// Formats [calories] as a rounded integer string, or "--" if null/zero.
  static String formatCalories(double? calories) {
    if (calories == null || calories <= 0) return '--';
    return calories.round().toString();
  }

  /// Returns the run title, or a time-based default (e.g. "Morning Run") if null.
  static String getRunTitle(String? title, DateTime? startTime) {
    if (title != null && title.trim().isNotEmpty) {
      return title;
    }
    final start = startTime?.toLocal() ?? DateTime.now();
    final hour = start.hour;
    if (hour >= 5 && hour < 12) {
      return 'Morning Run';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon Run';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening Run';
    } else {
      return 'Night Run';
    }
  }
}
