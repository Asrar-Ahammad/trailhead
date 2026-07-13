import re

# 1. week_details_screen.dart
with open('lib/features/you/presentation/week_details_screen.dart', 'r') as f:
    content = f.read()

# Make sure it's ConsumerStatefulWidget
content = content.replace("class WeekDetailsScreen extends StatefulWidget", "class WeekDetailsScreen extends ConsumerStatefulWidget")
content = content.replace("State<WeekDetailsScreen> createState() => _WeekDetailsScreenState();", "ConsumerState<WeekDetailsScreen> createState() => _WeekDetailsScreenState();")
content = content.replace("class _WeekDetailsScreenState extends State<WeekDetailsScreen>", "class _WeekDetailsScreenState extends ConsumerState<WeekDetailsScreen>")

# Fix useMiles not found in _buildStatItem
# _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) -> add useMiles if needed, but it's easier to just call ref.watch inside build and pass it. Wait, the errors are at line 87 and 124, which are probably inside other methods like _buildProgressCard or _buildActivityList.
# Let's replace `Widget build(BuildContext context)` in all methods that don't have it, or just use `ref.watch` if they do. Since it's ConsumerState, we can use `ref.watch` in `build`, but we need it where formatPace/Distance is called.
content = content.replace("RunFormatUtils.formatDistance(widget.report.totalDistanceM, useMiles)", "RunFormatUtils.formatDistance(widget.report.totalDistanceM, ref.watch(distanceUnitProvider))")
content = content.replace("RunFormatUtils.getUnitString(useMiles)", "RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")
content = content.replace("RunFormatUtils.formatPace(widget.report.totalDistanceM, widget.report.totalDurationS, useMiles)", "RunFormatUtils.formatPace(widget.report.totalDistanceM, widget.report.totalDurationS, ref.watch(distanceUnitProvider))")

# Remove the unused `useMiles` from `build` method
content = content.replace("final useMiles = ref.watch(distanceUnitProvider);", "")

with open('lib/features/you/presentation/week_details_screen.dart', 'w') as f:
    f.write(content)


# 2. weekly_reports_list_screen.dart
with open('lib/features/you/presentation/weekly_reports_list_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("class WeeklyReportsListScreen extends StatelessWidget", "class WeeklyReportsListScreen extends ConsumerWidget")
content = content.replace("Widget build(BuildContext context)", "Widget build(BuildContext context, WidgetRef ref)")

content = content.replace("RunFormatUtils.formatDistance(report.totalDistanceM, useMiles)", "RunFormatUtils.formatDistance(report.totalDistanceM, ref.watch(distanceUnitProvider))")
content = content.replace("RunFormatUtils.getUnitString(useMiles)", "RunFormatUtils.getUnitString(ref.watch(distanceUnitProvider))")
content = content.replace("final useMiles = ref.watch(distanceUnitProvider);", "")

with open('lib/features/you/presentation/weekly_reports_list_screen.dart', 'w') as f:
    f.write(content)


# 3. you_screen.dart
with open('lib/features/you/presentation/you_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("final useMiles = ref.watch(distanceUnitProvider);", "")
content = content.replace("final paceStr = formatPace(pr.category, pr.value, useMiles);", "final paceStr = formatPace(pr.category, pr.value, ref.watch(distanceUnitProvider));")

with open('lib/features/you/presentation/you_screen.dart', 'w') as f:
    f.write(content)
