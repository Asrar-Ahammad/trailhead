import re

# 1. run_charts_section.dart: missing import
with open('lib/features/history/presentation/widgets/run_charts_section.dart', 'r') as f:
    content = f.read()

if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
    content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content

with open('lib/features/history/presentation/widgets/run_charts_section.dart', 'w') as f:
    f.write(content)


# 2. active_run_screen.dart: _TargetPaceSelector, _ActivityTypeSelector extending StatelessWidget but using WidgetRef, and _LocationButtonState using WidgetRef
with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

# Replace class _TargetPaceSelector extends StatelessWidget -> class _TargetPaceSelector extends ConsumerWidget
content = content.replace("class _TargetPaceSelector extends StatelessWidget", "class _TargetPaceSelector extends ConsumerWidget")

# Replace class _ActivityTypeSelector extends StatelessWidget -> class _ActivityTypeSelector extends ConsumerWidget
content = content.replace("class _ActivityTypeSelector extends StatelessWidget", "class _ActivityTypeSelector extends ConsumerWidget")

# Replace class _LocationButtonState extends State<_LocationButton>
content = content.replace("class _LocationButtonState extends State<_LocationButton>", "class _LocationButtonState extends ConsumerState<_LocationButton>")
content = content.replace("class _LocationButton extends StatefulWidget", "class _LocationButton extends ConsumerStatefulWidget")
content = content.replace("State<_LocationButton> createState() => _LocationButtonState();", "ConsumerState<_LocationButton> createState() => _LocationButtonState();")
content = re.sub(r"class _LocationButtonState extends ConsumerState<_LocationButton>\s*\{\s*@override\s*Widget build\(BuildContext context, WidgetRef ref\)", r"class _LocationButtonState extends ConsumerState<_LocationButton> {\n  @override\n  Widget build(BuildContext context)", content, flags=re.MULTILINE)

# We should also revert `Widget build(BuildContext context, WidgetRef ref)` back to `Widget build(BuildContext context)` for ALL `State` or `ConsumerState` classes because only `ConsumerWidget` has `ref` in `build`, while `ConsumerState` has `ref` globally.
content = re.sub(r"(class \w+ extends (?:Consumer)?State<.*?>\s*\{.*?Widget build\(BuildContext context), WidgetRef ref\)", r"\1", content, flags=re.DOTALL)
# The above regex might be too broad or fail due to distance between class and build.
# Instead, let's just do targeted replacement:
content = content.replace("class _LocationButtonState extends ConsumerState<_LocationButton> {\n  @override\n  Widget build(BuildContext context, WidgetRef ref) {", "class _LocationButtonState extends ConsumerState<_LocationButton> {\n  @override\n  Widget build(BuildContext context) {")
content = content.replace("class _PaceChartPainter extends CustomPainter {\n  final List<RunPointIsar> points;\n  final double targetPaceSPerKm;\n  final AppColors colors;\n\n  _PaceChartPainter({\n    required this.points,\n    required this.targetPaceSPerKm,\n    required this.colors,\n  });\n\n  @override\n  void paint(Canvas canvas, Size size) {", "class _PaceChartPainter extends CustomPainter {\n  final List<RunPointIsar> points;\n  final double targetPaceSPerKm;\n  final AppColors colors;\n\n  _PaceChartPainter({\n    required this.points,\n    required this.targetPaceSPerKm,\n    required this.colors,\n  });\n\n  @override\n  void paint(Canvas canvas, Size size) {")

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)

