import re

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'r') as f:
    content = f.read()

content = content.replace("Widget _buildDistanceChart(List<WeeklyReportModel> weeklyReports, AppColors retroColors) {", "Widget _buildDistanceChart(List<WeeklyReportModel> weeklyReports, AppColors retroColors, bool useMiles) {")
content = content.replace("_buildDistanceChart(data.weeklyReports, retroColors),", "_buildDistanceChart(data.weeklyReports, retroColors, useMiles),")
content = content.replace("ref.watch(distanceUnitProvider)", "useMiles")

# We also need to add useMiles inside build
if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
    content = content.replace("Widget build(BuildContext context, WidgetRef ref) {", "Widget build(BuildContext context, WidgetRef ref) {\n    final useMiles = ref.watch(distanceUnitProvider);")

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'w') as f:
    f.write(content)

