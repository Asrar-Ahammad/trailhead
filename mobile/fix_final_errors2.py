import re

with open('lib/features/history/presentation/run_detail_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("ConsumerConsumerState", "ConsumerState")

with open('lib/features/history/presentation/run_detail_screen.dart', 'w') as f:
    f.write(content)

with open('lib/features/history/presentation/widgets/run_metric_chart.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';" not in content:
    content = "import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';\n" + content

with open('lib/features/history/presentation/widgets/run_metric_chart.dart', 'w') as f:
    f.write(content)

