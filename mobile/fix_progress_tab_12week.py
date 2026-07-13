import re

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'r') as f:
    content = f.read()

content = content.replace("Widget _build12WeekChart(AppColors retroColors) {", "Widget _build12WeekChart(AppColors retroColors, bool useMiles) {")
content = content.replace("_build12WeekChart(retroColors),", "_build12WeekChart(retroColors, useMiles),")

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'w') as f:
    f.write(content)

