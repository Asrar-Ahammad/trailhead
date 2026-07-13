import re

with open('lib/features/history/presentation/widgets/run_charts_section.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = content.replace("import 'package:trailhead_mobile/features/history/presentation/widgets/run_metric_chart.dart';", 
"""import 'package:trailhead_mobile/features/history/presentation/widgets/run_metric_chart.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';""")

build_method = "  Widget build(BuildContext context, WidgetRef ref) {"
if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
    content = content.replace(build_method, build_method + "\n    final useMiles = ref.watch(distanceUnitProvider);")

content = content.replace("_formatPace(avgPace)", "_formatPace(avgPace, useMiles)")
content = content.replace("_formatPace(elapsedPaceSPerKm)", "_formatPace(elapsedPaceSPerKm, useMiles)")
content = content.replace("_formatPace(fastestPaceSPerKm)", "_formatPace(fastestPaceSPerKm, useMiles)")

old_format_pace = r'''  String _formatPace\(double seconds\) \{
    final m = seconds ~/ 60;
    final s = \(seconds % 60\)\.round\(\);
    return '\$m:\$\{s\.toString\(\)\.padLeft\(2, '0'\)\} /km';
  \}'''

new_format_pace = '''  String _formatPace(double seconds, bool useMiles) {
    if (useMiles) seconds *= 1.60934;
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /${RunFormatUtils.getUnitString(useMiles)}';
  }'''

content = re.sub(old_format_pace, new_format_pace, content)

with open('lib/features/history/presentation/widgets/run_charts_section.dart', 'w') as f:
    f.write(content)
