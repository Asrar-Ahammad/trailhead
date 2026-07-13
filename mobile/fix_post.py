import re

with open('lib/features/run_tracking/presentation/post_run_summary_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", 
"""import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';""")

build_method = "  Widget build(BuildContext context) {"
if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
    content = content.replace(build_method, build_method + "\n    final useMiles = ref.watch(distanceUnitProvider);")

content = content.replace("RunFormatUtils.formatDistanceKm(val)", "RunFormatUtils.formatDistance(val, useMiles)")
content = content.replace("RunFormatUtils.formatPace(1000, val.toInt())", "RunFormatUtils.formatPace(1000, val.toInt(), useMiles)")
content = content.replace("'DISTANCE (KM)'", "'DISTANCE (${RunFormatUtils.getUnitStringUpper(useMiles)})'")
content = content.replace("'PACE /KM'", "'PACE /${RunFormatUtils.getUnitStringUpper(useMiles)}'")

with open('lib/features/run_tracking/presentation/post_run_summary_screen.dart', 'w') as f:
    f.write(content)
