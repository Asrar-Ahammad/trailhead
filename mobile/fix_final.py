import re

# 1. week_details_screen.dart
with open('lib/features/you/presentation/week_details_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("ConsumerConsumerState", "ConsumerState")
if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content

with open('lib/features/you/presentation/week_details_screen.dart', 'w') as f:
    f.write(content)


# 2. weekly_reports_list_screen.dart
with open('lib/features/you/presentation/weekly_reports_list_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';\n" + content

with open('lib/features/you/presentation/weekly_reports_list_screen.dart', 'w') as f:
    f.write(content)

