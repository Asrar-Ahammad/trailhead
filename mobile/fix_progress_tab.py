import re

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';" not in content:
    content = "import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';\n" + content
if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
    content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content

# Make ConsumerWidget
if "class ProgressTab extends StatelessWidget" in content:
    content = content.replace("class ProgressTab extends StatelessWidget", "class ProgressTab extends ConsumerWidget")
    content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

with open('lib/features/you/presentation/widgets/progress_tab.dart', 'w') as f:
    f.write(content)

