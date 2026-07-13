import re

with open('lib/features/you/presentation/week_details_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = content.replace("import 'package:trailhead_mobile/features/stats/data/models/weekly_report_isar.dart';", 
"""import 'package:trailhead_mobile/features/stats/data/models/weekly_report_isar.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';""")

build_method = "  Widget build(BuildContext context) {"
if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
    content = content.replace(build_method, build_method + "\n    final useMiles = ref.watch(distanceUnitProvider);")

content = content.replace("RunFormatUtils.formatDistanceKm(widget.report.totalDistanceM) + ' km'", "RunFormatUtils.formatDistance(widget.report.totalDistanceM, useMiles) + ' ${RunFormatUtils.getUnitString(useMiles)}'")
content = content.replace("RunFormatUtils.formatPace(widget.report.totalDistanceM, widget.report.totalDurationS)", "RunFormatUtils.formatPace(widget.report.totalDistanceM, widget.report.totalDurationS, useMiles)")
content = content.replace("'Avg Pace /km'", "'Avg Pace /${RunFormatUtils.getUnitString(useMiles)}'")

with open('lib/features/you/presentation/week_details_screen.dart', 'w') as f:
    f.write(content)
