import re

with open('lib/features/history/presentation/widgets/results_section.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = content.replace("import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';", 
"""import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';""")

# Update _formatValue
old_format_value = r'''  String _formatValue\(String category, double value\) \{
    if \(category == 'longest_run'\) \{
      return '\$\{\(value / 1000\)\.toStringAsFixed\(2\)\} km';
    \} else if \(category == 'max_elevation'\) \{'''
new_format_value = '''  String _formatValue(String category, double value, bool useMiles) {
    if (category == 'longest_run') {
      return '${RunFormatUtils.formatDistance(value, useMiles)} ${RunFormatUtils.getUnitString(useMiles)}';
    } else if (category == 'max_elevation') {'''
content = re.sub(old_format_value, new_format_value, content)

# Update _formatPace
old_format_pace = r'''  String _formatPace\(String category, double value\) \{
    // For distance based categories, calculate pace
    double distanceM = 0;
    if \(category == '100m'\) distanceM = 100;
    else if \(category == '400m'\) distanceM = 400;
    else if \(category == '1k'\) distanceM = 1000;
    else if \(category == '1 mile'\) distanceM = 1609\.34;
    else if \(category == '5k'\) distanceM = 5000;
    else if \(category == '10k'\) distanceM = 10000;
    else if \(category == 'half'\) distanceM = 21097\.5;
    else if \(category == 'marathon'\) distanceM = 42195;
    
    if \(distanceM > 0\) \{
      final paceSPerKm = value / \(distanceM / 1000\);
      final paceMins = \(paceSPerKm / 60\)\.floor\(\);
      final paceSecs = \(paceSPerKm % 60\)\.floor\(\)\.toString\(\)\.padLeft\(2, '0'\);
      return '\$paceMins:\$paceSecs /km';
    \}
    return '';
  \}'''
new_format_pace = '''  String _formatPace(String category, double value, bool useMiles) {
    // For distance based categories, calculate pace
    double distanceM = 0;
    if (category == '100m') distanceM = 100;
    else if (category == '400m') distanceM = 400;
    else if (category == '1k') distanceM = 1000;
    else if (category == '1 mile') distanceM = 1609.34;
    else if (category == '5k') distanceM = 5000;
    else if (category == '10k') distanceM = 10000;
    else if (category == 'half') distanceM = 21097.5;
    else if (category == 'marathon') distanceM = 42195;
    
    if (distanceM > 0) {
      return RunFormatUtils.formatPace(distanceM, value.toInt(), useMiles) + ' /${RunFormatUtils.getUnitString(useMiles)}';
    }
    return '';
  }'''
content = re.sub(old_format_pace, new_format_pace, content)

# Inject ref.watch in build
build_method = "  Widget build(BuildContext context, WidgetRef ref) {"
if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
    content = content.replace(build_method, build_method + "\n    final useMiles = ref.watch(distanceUnitProvider);")

content = content.replace("final timeStr = _formatValue(pr.category, pr.value);", "final timeStr = _formatValue(pr.category, pr.value, useMiles);")
content = content.replace("final paceStr = _formatPace(pr.category, pr.value);", "final paceStr = _formatPace(pr.category, pr.value, useMiles);")

with open('lib/features/history/presentation/widgets/results_section.dart', 'w') as f:
    f.write(content)
