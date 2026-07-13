import re

# 1. run_detail_screen.dart
with open('lib/features/history/presentation/run_detail_screen.dart', 'r') as f:
    content = f.read()

# Add import if missing
if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content

# Check if ConsumerState
content = content.replace("class RunDetailScreen extends StatefulWidget", "class RunDetailScreen extends ConsumerStatefulWidget")
content = content.replace("State<RunDetailScreen> createState() => _RunDetailScreenState();", "ConsumerState<RunDetailScreen> createState() => _RunDetailScreenState();")
content = content.replace("class _RunDetailScreenState extends State<RunDetailScreen>", "class _RunDetailScreenState extends ConsumerState<RunDetailScreen>")

content = content.replace("'${distanceKm.toStringAsFixed(2)} km'", "RunFormatUtils.formatDistance(widget.run.distanceM ?? 0, ref.watch(distanceUnitProvider)) + ' ' + RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")

with open('lib/features/history/presentation/run_detail_screen.dart', 'w') as f:
    f.write(content)

# 2. home_screen.dart
with open('lib/features/home/presentation/home_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content
    
content = content.replace("'${value.toInt()} km'", "RunFormatUtils.formatDistance(value * 1000, ref.watch(distanceUnitProvider)) + ' ' + RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")
content = content.replace("'${((summary.mostRecentRun!.distanceM ?? 0) / 1000).toStringAsFixed(2)} km'", "RunFormatUtils.formatDistance(summary.mostRecentRun!.distanceM ?? 0, ref.watch(distanceUnitProvider)) + ' ' + RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")

with open('lib/features/home/presentation/home_screen.dart', 'w') as f:
    f.write(content)

# 3. activity_card.dart
with open('lib/features/you/presentation/widgets/activity_card.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content
if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
    content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content

# Make ConsumerWidget
content = content.replace("class ActivityCard extends StatelessWidget", "class ActivityCard extends ConsumerWidget")
content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")
content = content.replace("Widget build(BuildContext context, WidgetRef ref) {", "Widget build(BuildContext context, WidgetRef ref) {\n    final useMiles = ref.watch(distanceUnitProvider);")

content = content.replace("'${distanceKm.toStringAsFixed(2)} km in $durationMins min • '", "(RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles)) + ' ' + RunFormatUtils.getUnitString(useMiles) + ' in $durationMins min • '")
content = content.replace("'${distanceKm.toStringAsFixed(2)} km in $durationMins min'", "(RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles)) + ' ' + RunFormatUtils.getUnitString(useMiles) + ' in $durationMins min'")

with open('lib/features/you/presentation/widgets/activity_card.dart', 'w') as f:
    f.write(content)

# 4. progress_tab.dart
with open('lib/features/you/presentation/widgets/progress_tab.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content
    
content = content.replace("'${value.toInt()} km'", "RunFormatUtils.formatDistance(value * 1000, ref.watch(distanceUnitProvider)) + ' ' + RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'w') as f:
    f.write(content)

# 5. run_metric_chart.dart
with open('lib/features/history/presentation/widgets/run_metric_chart.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content
if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
    content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content

# Make ConsumerWidget
if "class RunMetricChart extends StatelessWidget" in content:
    content = content.replace("class RunMetricChart extends StatelessWidget", "class RunMetricChart extends ConsumerWidget")
    content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

content = content.replace("'${value.toStringAsFixed(1)} km'", "RunFormatUtils.formatDistance(value * 1000, ref.watch(distanceUnitProvider)) + ' ' + RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")

with open('lib/features/history/presentation/widgets/run_metric_chart.dart', 'w') as f:
    f.write(content)

# 6. chat_screen.dart (AI Context)
with open('lib/features/chat/presentation/chat_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content
if "import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';" not in content:
    content = "import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';\n" + content

content = content.replace('buffer.writeln("- $date: $type, $distKm km in $durMins mins.");',
"""
      final useMiles = ref.read(distanceUnitProvider);
      final distStr = RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles);
      final unitStr = RunFormatUtils.getUnitString(useMiles);
      buffer.writeln("- $date: $type, $distStr $unitStr in $durMins mins.");
""")

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(content)

