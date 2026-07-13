import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

# 1. Update _StatPanel background
content = re.sub(
    r"color: const Color\(0xFF1E1E1E\), // Dark card color",
    "color: colors.surfaceRaised, // Themed card color",
    content
)
# (In case it was written differently)
content = re.sub(
    r"color: const Color\(0xFF1E1E1E\), // Dark sheet color",
    "color: colors.surfaceRaised, // Themed sheet color",
    content
)

# 2. Update _StatColumn calls in _StatPanel
content = re.sub(
    r"_StatColumn\(\s*value: (.*?),\s*label: (.*?),(\s*isCenter: true,)?\s*\)",
    r"_StatColumn(\n                value: \1,\n                label: \2,\n                colors: colors,\3\n              )",
    content
)

# 3. Update _StatColumn definition and implementation
stat_col_old = r'''class _StatColumn extends StatelessWidget \{
  const _StatColumn\(\{required this\.value, required this\.label, this\.isCenter = false\}\);
  final String value;
  final String label;
  final bool isCenter;

  @override
  Widget build\(BuildContext context\) \{
    return Expanded\(
      child: Column\(
        children: \[
          if \(isCenter\) 
            Padding\(
              padding: const EdgeInsets\.only\(bottom: 8\),
              child: Row\(
                mainAxisAlignment: MainAxisAlignment\.center,
                children: \[
                  Container\(width: 8, height: 8, decoration: const BoxDecoration\(color: Colors\.white, shape: BoxShape\.circle\)\),
                  const SizedBox\(width: 4\),
                  Container\(width: 16, height: 4, decoration: BoxDecoration\(color: Colors\.white, borderRadius: BorderRadius\.circular\(2\)\)\),
                  const SizedBox\(width: 4\),
                  Container\(width: 16, height: 4, decoration: BoxDecoration\(color: Colors\.white, borderRadius: BorderRadius\.circular\(2\)\)\),
                \],
              \),
            \),
          Text\(
            value,
            style: const TextStyle\(
              fontSize: 40,
              fontWeight: FontWeight\.bold,
              color: Colors\.white,
              letterSpacing: 1\.0,
            \),
          \),
          const SizedBox\(height: 4\),
          Text\(
            label,
            style: const TextStyle\(
              fontSize: 14,
              color: Colors\.white70,
              fontWeight: FontWeight\.w500,
            \),
          \),
        \],
      \),
    \);
  \}
\}'''

stat_col_new = '''class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label, required this.colors, this.isCenter = false});
  final String value;
  final String label;
  final AppColors colors;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (isCenter) 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.textPrimary, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Container(width: 16, height: 4, decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Container(width: 16, height: 4, decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}'''

content = re.sub(stat_col_old, stat_col_new, content)

# 4. Update _CircularAction calls in _RunControls
# Left Action
content = re.sub(
    r"color: const Color\(0xFF2C2C2C\),",
    r"color: colors.surface,",
    content
)

# Right Action (Pace)
# (Same regex applies, it will replace both const Color(0xFF2C2C2C) instances)

# 5. Update _CircularAction definition
circ_old = r'''class _CircularAction extends StatelessWidget \{
  const _CircularAction\(\{
    required this\.icon,
    required this\.label,
    required this\.color,
    required this\.iconColor,
    required this\.onTap,
  \}\);

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build\(BuildContext context\) \{
    return Column\(
      mainAxisSize: MainAxisSize\.min,
      children: \[
        GestureDetector\(
          onTap: onTap,
          child: Container\(
            width: 70,
            height: 70,
            decoration: BoxDecoration\(
              color: color,
              shape: BoxShape\.circle,
            \),
            child: Icon\(icon, color: iconColor, size: 32\),
          \),
        \),
        const SizedBox\(height: 12\),
        Text\(
          label,
          style: const TextStyle\(
            fontSize: 14,
            color: Colors\.white,
            fontWeight: FontWeight\.w500,
          \),
        \),
      \],
    \);
  \}
\}'''

circ_new = '''class _CircularAction extends StatelessWidget {
  const _CircularAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}'''

content = re.sub(circ_old, circ_new, content)

# 6. Actually, let's inject textColor: colors.textPrimary to the _CircularAction calls
content = re.sub(
    r"iconColor: isIdle \? colors\.accent : colors\.error,\n\s*onTap: \(\) \{",
    r"iconColor: isIdle ? colors.accent : colors.error,\n                    textColor: colors.textPrimary,\n                    onTap: () {",
    content
)
content = re.sub(
    r"iconColor: Colors\.white,\n\s*onTap: \(\) \{",
    r"iconColor: colors.textPrimary,\n                    textColor: colors.textPrimary,\n                    onTap: () {",
    content
)

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)

