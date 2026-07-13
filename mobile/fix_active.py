import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

# Replace StatelessWidget with ConsumerWidget for all widgets that use useMiles
widgets = [
    '_GpsWeakBanner',
    '_StatusBar',
    '_StatPanel',
    '_StatColumn',
    '_PaceComparisonBadge',
    '_RunControls',
    '_CircularAction',
    '_CircleButton',
    '_StopBottomSheet',
    '_SheetButton'
]

for w in widgets:
    content = re.sub(f"class {w} extends StatelessWidget", f"class {w} extends ConsumerWidget", content)

# Since we might match Widget build(BuildContext context) generally in those widgets,
# the easiest way is to just replace ALL `Widget build(BuildContext context)` with `Widget build(BuildContext context, WidgetRef ref)` in the whole file EXCEPT for StatefulWidget or state classes that already have it.
# Wait, ConsumerState's build already has `Widget build(BuildContext context)`! We can't replace it there.
# If a widget is a ConsumerWidget, its build MUST be `Widget build(BuildContext context, WidgetRef ref)`.

content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

# But wait, ConsumerState<T> build is `Widget build(BuildContext context)`.
# Let's fix _ActiveRunScreenState and _PaceChartPainter (CustomPainter) which don't have WidgetRef.
content = content.replace("class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> {\n", "class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> {\n")
# Actually, if I just replaced all, I need to revert for _ActiveRunScreenState
content = re.sub(r"(class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> \{.*?Widget build\(BuildContext context), WidgetRef ref\)", r"\1", content, flags=re.DOTALL)

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)
