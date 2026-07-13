import re

# 1. post_run_summary_screen.dart
with open('lib/features/run_tracking/presentation/post_run_summary_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("Widget _buildStatsGrid(AppColors colors) {", "Widget _buildStatsGrid(AppColors colors, bool useMiles) {")
content = content.replace("_buildStatsGrid(colors),", "_buildStatsGrid(colors, useMiles),")

with open('lib/features/run_tracking/presentation/post_run_summary_screen.dart', 'w') as f:
    f.write(content)

# 2. run_charts_section.dart
with open('lib/features/history/presentation/widgets/run_charts_section.dart', 'r') as f:
    content = f.read()

# I need to check if RunChartsSection is a ConsumerWidget
if "class RunChartsSection extends StatelessWidget" in content:
    content = content.replace("class RunChartsSection extends StatelessWidget", "class RunChartsSection extends ConsumerWidget")
    content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")
    if "final useMiles = ref.watch(distanceUnitProvider);" not in content:
        content = content.replace("Widget build(BuildContext context, WidgetRef ref) {", "Widget build(BuildContext context, WidgetRef ref) {\n    final useMiles = ref.watch(distanceUnitProvider);")

with open('lib/features/history/presentation/widgets/run_charts_section.dart', 'w') as f:
    f.write(content)

