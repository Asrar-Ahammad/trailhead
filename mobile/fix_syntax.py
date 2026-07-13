import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("Widget build(BuildContext context {", "Widget build(BuildContext context) {")
content = content.replace("ConsumerConsumerState", "ConsumerState")

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)
