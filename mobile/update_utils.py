import re

with open('lib/features/run_tracking/application/run_format_utils.dart', 'r') as f:
    content = f.read()

# Replace formatPace
old_pace = r'''  static String formatPace\(double distanceM, int durationS\) \{
    if \(distanceM <= 0 \|\| durationS <= 0\) return '-:--';
    final double distanceKm = distanceM / 1000\.0;
    final double paceS      = durationS / distanceKm;
    final int paceMin  = \(paceS / 60\)\.floor\(\);
    final int paceSec  = \(paceS % 60\)\.round\(\);
    return '\$\{paceMin\.toString\(\)\.padLeft\(2, '0'\)\}:\$\{paceSec\.toString\(\)\.padLeft\(2, '0'\)\}';
  \}'''

new_pace = '''  static String formatPace(double distanceM, int durationS, bool useMiles) {
    if (distanceM <= 0 || durationS <= 0) return '-:--';
    final double dist = useMiles ? distanceM / 1609.34 : distanceM / 1000.0;
    final double paceS      = durationS / dist;
    final int paceMin  = (paceS / 60).floor();
    final int paceSec  = (paceS % 60).round();
    return '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')}';
  }'''

content = re.sub(old_pace, new_pace, content)

# Replace formatDistanceKm
old_dist = r'''  static String formatDistanceKm\(double distanceM\) \{
    return \(distanceM / 1000\.0\)\.toStringAsFixed\(2\);
  \}'''

new_dist = '''  static String formatDistance(double distanceM, bool useMiles) {
    final dist = useMiles ? distanceM / 1609.34 : distanceM / 1000.0;
    return dist.toStringAsFixed(2);
  }
  
  static String getUnitString(bool useMiles) => useMiles ? 'mi' : 'km';
  static String getUnitStringUpper(bool useMiles) => useMiles ? 'MI' : 'KM';'''

content = re.sub(old_dist, new_dist, content)

with open('lib/features/run_tracking/application/run_format_utils.dart', 'w') as f:
    f.write(content)
