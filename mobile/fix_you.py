import re

with open('lib/features/you/presentation/you_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = content.replace("import 'package:trailhead_mobile/features/profile/presentation/settings_screen.dart';", 
"""import 'package:trailhead_mobile/features/profile/presentation/settings_screen.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';""")

build_method = "  Widget build(BuildContext context) {"
if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
    content = content.replace(build_method, build_method + "\n    final useMiles = ref.watch(distanceUnitProvider);")

# It has a local formatPace inside _YouScreenState?
# Let's search for formatPace in you_screen.dart
old_format_pace = r'''  String formatPace\(String category, double value\) \{
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

new_format_pace = '''  String formatPace(String category, double value, bool useMiles) {
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

content = content.replace("final paceStr = formatPace(pr.category, pr.value);", "final paceStr = formatPace(pr.category, pr.value, useMiles);")

with open('lib/features/you/presentation/you_screen.dart', 'w') as f:
    f.write(content)
